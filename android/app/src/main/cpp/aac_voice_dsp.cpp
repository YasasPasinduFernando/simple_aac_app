#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

#ifdef __ANDROID__
#include <jni.h>
#endif

#include "world/cheaptrick.h"
#include "world/d4c.h"
#include "world/dio.h"
#include "world/matlabfunctions.h"
#include "world/stonemask.h"
#include "world/synthesis.h"

#define AAC_EXPORT __attribute__((visibility("default")))

namespace {

constexpr float kPi = 3.14159265358979323846f;

struct WavData {
    int sampleRate = 22050;
    std::vector<double> samples;
};

bool readWav(const std::string& path, WavData& out) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return false;

    char hdr[12];
    f.read(hdr, 12);
    if (!f || std::string(hdr, 4) != "RIFF" || std::string(hdr + 8, 4) != "WAVE") {
        return false;
    }

    uint16_t audioFormat = 1;
    uint16_t channels = 1;
    uint16_t bitsPerSample = 16;
    uint32_t sampleRate = 22050;
    std::vector<uint8_t> rawData;

    while (f) {
        char chunkId[4];
        uint32_t chunkSize = 0;
        f.read(chunkId, 4);
        f.read(reinterpret_cast<char*>(&chunkSize), 4);
        if (!f) break;

        std::string id(chunkId, 4);
        if (id == "fmt " && chunkSize >= 16) {
            std::vector<uint8_t> fmt(chunkSize);
            f.read(reinterpret_cast<char*>(fmt.data()), chunkSize);
            audioFormat = *reinterpret_cast<uint16_t*>(&fmt[0]);
            channels = std::max<uint16_t>(1, *reinterpret_cast<uint16_t*>(&fmt[2]));
            sampleRate = std::max<uint32_t>(8000, *reinterpret_cast<uint32_t*>(&fmt[4]));
            bitsPerSample = *reinterpret_cast<uint16_t*>(&fmt[14]);
            if (chunkSize & 1) f.seekg(1, std::ios::cur);
        } else if (id == "data") {
            rawData.resize(chunkSize);
            f.read(reinterpret_cast<char*>(rawData.data()), chunkSize);
            if (chunkSize & 1) f.seekg(1, std::ios::cur);
        } else {
            f.seekg(static_cast<std::streamoff>(chunkSize + (chunkSize & 1)), std::ios::cur);
        }
    }

    if (rawData.empty()) return false;
    out.sampleRate = static_cast<int>(sampleRate);

    if (audioFormat == 1 && bitsPerSample == 16) {
        const size_t n = rawData.size() / (2 * channels);
        out.samples.resize(n);
        const int16_t* p = reinterpret_cast<const int16_t*>(rawData.data());
        for (size_t i = 0; i < n; ++i) {
            double sum = 0.0;
            for (int c = 0; c < channels; ++c) {
                sum += static_cast<double>(p[i * channels + c]) / 32768.0;
            }
            out.samples[i] = sum / static_cast<double>(channels);
        }
        return !out.samples.empty();
    }

    if (audioFormat == 3 && bitsPerSample == 32) {
        const size_t n = rawData.size() / (4 * channels);
        out.samples.resize(n);
        const float* p = reinterpret_cast<const float*>(rawData.data());
        for (size_t i = 0; i < n; ++i) {
            double sum = 0.0;
            for (int c = 0; c < channels; ++c) {
                sum += static_cast<double>(p[i * channels + c]);
            }
            out.samples[i] = sum / static_cast<double>(channels);
        }
        return !out.samples.empty();
    }

    return false;
}

bool writeWav(const std::string& path, const std::vector<double>& samples, int sr) {
    if (samples.empty() || sr <= 0) return false;
    std::ofstream f(path, std::ios::binary);
    if (!f) return false;

    const uint32_t dataBytes = static_cast<uint32_t>(samples.size() * sizeof(int16_t));
    const uint32_t riffSize = 36 + dataBytes;
    const uint16_t pcmFormat = 1;
    const uint16_t channels = 1;
    const uint16_t blockAlign = 2;
    const uint16_t bitsPerSample = 16;
    const uint32_t srU = static_cast<uint32_t>(sr);
    const uint32_t byteRate = srU * 2;
    const uint32_t fmtSize = 16;

    f.write("RIFF", 4);
    f.write(reinterpret_cast<const char*>(&riffSize), 4);
    f.write("WAVEfmt ", 8);
    f.write(reinterpret_cast<const char*>(&fmtSize), 4);
    f.write(reinterpret_cast<const char*>(&pcmFormat), 2);
    f.write(reinterpret_cast<const char*>(&channels), 2);
    f.write(reinterpret_cast<const char*>(&srU), 4);
    f.write(reinterpret_cast<const char*>(&byteRate), 4);
    f.write(reinterpret_cast<const char*>(&blockAlign), 2);
    f.write(reinterpret_cast<const char*>(&bitsPerSample), 2);
    f.write("data", 4);
    f.write(reinterpret_cast<const char*>(&dataBytes), 4);

    std::vector<int16_t> pcm(samples.size());
    for (size_t i = 0; i < samples.size(); ++i) {
        const double clamped = std::max(-1.0, std::min(1.0, samples[i]));
        pcm[i] = static_cast<int16_t>(std::lrint(clamped * 32767.0));
    }
    f.write(reinterpret_cast<const char*>(pcm.data()), dataBytes);
    f.flush();
    return f.good();
}

struct Biquad {
    double b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0;
    double z1 = 0.0, z2 = 0.0;

    void setHighpass(double fc, double sr, double q = 0.707) {
        const double w0 = 2.0 * kPi * std::min(fc, sr * 0.45) / sr;
        const double cs = std::cos(w0);
        const double sn = std::sin(w0);
        const double alpha = sn / (2.0 * q);
        const double a0 = 1.0 + alpha;
        b0 = (1.0 + cs) * 0.5 / a0;
        b1 = -(1.0 + cs) / a0;
        b2 = b0;
        a1 = (-2.0 * cs) / a0;
        a2 = (1.0 - alpha) / a0;
        z1 = z2 = 0.0;
    }

    void setLowpass(double fc, double sr, double q = 0.707) {
        const double w0 = 2.0 * kPi * std::min(fc, sr * 0.45) / sr;
        const double cs = std::cos(w0);
        const double sn = std::sin(w0);
        const double alpha = sn / (2.0 * q);
        const double a0 = 1.0 + alpha;
        b0 = (1.0 - cs) * 0.5 / a0;
        b1 = (1.0 - cs) / a0;
        b2 = b0;
        a1 = (-2.0 * cs) / a0;
        a2 = (1.0 - alpha) / a0;
        z1 = z2 = 0.0;
    }

    void setLowShelf(double fc, double sr, double gainDb) {
        const double A = std::pow(10.0, gainDb / 40.0);
        const double w0 = 2.0 * kPi * std::min(fc, sr * 0.45) / sr;
        const double cs = std::cos(w0);
        const double sn = std::sin(w0);
        const double beta = sn * std::sqrt(std::max(0.0, (A * A + 1.0) - (A - 1.0) * (A - 1.0)));
        const double a0 = (A + 1.0) + (A - 1.0) * cs + beta;
        b0 = A * ((A + 1.0) - (A - 1.0) * cs + beta) / a0;
        b1 = 2.0 * A * ((A - 1.0) - (A + 1.0) * cs) / a0;
        b2 = A * ((A + 1.0) - (A - 1.0) * cs - beta) / a0;
        a1 = -2.0 * ((A - 1.0) + (A + 1.0) * cs) / a0;
        a2 = ((A + 1.0) + (A - 1.0) * cs - beta) / a0;
        z1 = z2 = 0.0;
    }

    inline double tick(double x) {
        const double y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

// Energy-gated median F0 prevents silent/onset half-F0 octave errors.
double robustMedianF0(
    const std::vector<double>& x,
    int fs,
    const std::vector<double>& f0,
    double framePeriodMs
) {
    double gEnergy = 0.0;
    for (double v : x) gEnergy += v * v;
    const double gRms = std::sqrt(gEnergy / std::max<size_t>(1, x.size()));
    const int halfWin = std::max(1, static_cast<int>(0.015 * fs));

    std::vector<double> voiced;
    for (size_t i = 0; i < f0.size(); ++i) {
        if (f0[i] < 80.0 || f0[i] > 420.0) continue;
        const int center = static_cast<int>(i * (framePeriodMs * 0.001) * fs);
        const int s = std::max(0, center - halfWin);
        const int e = std::min<int>(static_cast<int>(x.size()), center + halfWin);
        double fe = 0.0;
        for (int k = s; k < e; ++k) fe += x[k] * x[k];
        if (std::sqrt(fe / std::max(1, e - s)) >= gRms * 0.40) {
            voiced.push_back(f0[i]);
        }
    }
    if (voiced.empty()) {
        for (double v : f0) {
            if (v > 80.0 && v < 420.0) voiced.push_back(v);
        }
    }
    if (voiced.empty()) return 200.0;
    std::sort(voiced.begin(), voiced.end());
    return voiced[voiced.size() / 2];
}

void cleanAndNormalize(std::vector<double>& y, int sr, bool polishMale) {
    if (y.empty() || sr <= 0) return;

    Biquad hp;
    hp.setHighpass(75.0, static_cast<double>(sr));
    for (double& v : y) v = hp.tick(v);

    if (polishMale) {
        // Gentle high-frequency breath/sibilance tame + chest warmth for native male voices.
        Biquad deHiss;
        deHiss.setLowpass(6800.0, static_cast<double>(sr), 0.707);
        Biquad chest;
        chest.setLowShelf(140.0, static_cast<double>(sr), 2.2);
        for (double& v : y) v = chest.tick(deHiss.tick(v));
    }

    double peak = 0.0;
    for (double v : y) peak = std::max(peak, std::abs(v));
    if (peak < 1e-5) return;

    const double thresh = peak * 0.015;
    size_t first = 0;
    size_t last = y.size();
    while (first < y.size() && std::abs(y[first]) < thresh) ++first;
    while (last > first && std::abs(y[last - 1]) < thresh) --last;

    const size_t leadPad = std::min<size_t>(static_cast<size_t>(0.025 * sr), first);
    first -= leadPad;
    last = std::min(y.size(), last + static_cast<size_t>(0.040 * sr));
    if (last > first) {
        y = std::vector<double>(y.begin() + first, y.begin() + last);
    }

    peak = 0.0;
    for (double v : y) peak = std::max(peak, std::abs(v));
    if (peak > 1e-5) {
        const double gain = std::min(12.0, 0.84 / peak);
        for (double& v : y) v = std::tanh(v * gain);
        double newPeak = 0.0;
        for (double v : y) newPeak = std::max(newPeak, std::abs(v));
        if (newPeak > 0.85) {
            const double rescale = 0.84 / newPeak;
            for (double& v : y) v *= rescale;
        }
    }

    const size_t fade = std::min<size_t>(static_cast<size_t>(0.005 * sr), y.size() / 4);
    for (size_t i = 0; i < fade; ++i) {
        const double g = static_cast<double>(i) / static_cast<double>(fade);
        y[i] *= g;
        y[y.size() - 1 - i] *= g;
    }
}

std::vector<double> processPcmSamples(
    const double* samples,
    int32_t numSamples,
    int32_t sampleRate,
    float targetF0Hz,
    float formantSemitones
) {
    std::vector<double> x(samples, samples + numSamples);
    if (targetF0Hz <= 0.0f && std::abs(formantSemitones) < 0.05f) {
        // Native Male path: skip vocoder completely, apply warmth + de-hiss + normalization.
        cleanAndNormalize(x, sampleRate, true);
        return x;
    }

    const double formantRatio = std::max(0.65, std::min(1.50, std::pow(2.0, formantSemitones / 12.0)));

    DioOption dioOpt;
    InitializeDioOption(&dioOpt);
    dioOpt.frame_period = 5.0;
    dioOpt.speed = 1;
    dioOpt.f0_floor = 71.0;
    dioOpt.f0_ceil = 550.0;
    dioOpt.allowed_range = 0.1;

    const int f0Len = GetSamplesForDIO(sampleRate, numSamples, dioOpt.frame_period);
    std::vector<double> f0(f0Len, 0.0);
    std::vector<double> timeAxis(f0Len, 0.0);
    std::vector<double> refinedF0(f0Len, 0.0);

    Dio(x.data(), numSamples, sampleRate, &dioOpt, timeAxis.data(), f0.data());
    StoneMask(x.data(), numSamples, sampleRate, timeAxis.data(), f0.data(), f0Len, refinedF0.data());

    const double medF0 = robustMedianF0(x, sampleRate, refinedF0, dioOpt.frame_period);
    const double f0Ratio = (targetF0Hz > 0.0f)
        ? std::max(0.55, std::min(2.35, static_cast<double>(targetF0Hz) / medF0))
        : 1.0;

    CheapTrickOption ctOpt;
    InitializeCheapTrickOption(sampleRate, &ctOpt);
    ctOpt.f0_floor = 71.0;
    const int fftSize = GetFFTSizeForCheapTrick(sampleRate, &ctOpt);
    ctOpt.fft_size = fftSize;
    const int bins = fftSize / 2 + 1;

    std::vector<double> specBuf(static_cast<size_t>(f0Len) * bins, 0.0);
    std::vector<double> apBuf(static_cast<size_t>(f0Len) * bins, 0.0);
    std::vector<double*> spec(f0Len), ap(f0Len);
    for (int i = 0; i < f0Len; ++i) {
        spec[i] = &specBuf[static_cast<size_t>(i) * bins];
        ap[i] = &apBuf[static_cast<size_t>(i) * bins];
    }

    CheapTrick(x.data(), numSamples, sampleRate, timeAxis.data(), refinedF0.data(), f0Len, &ctOpt, spec.data());

    D4COption d4cOpt;
    InitializeD4COption(&d4cOpt);
    d4cOpt.threshold = 0.85;
    D4C(x.data(), numSamples, sampleRate, timeAxis.data(), refinedF0.data(), f0Len, fftSize, &d4cOpt, ap.data());

    for (int i = 0; i < f0Len; ++i) {
        if (refinedF0[i] > 0.0) refinedF0[i] *= f0Ratio;
    }

    if (std::abs(formantRatio - 1.0) > 0.01) {
        std::vector<double> fx1(bins), fx2(bins), s1(bins), s2(bins);
        for (int j = 0; j < bins; ++j) {
            fx1[j] = formantRatio * j / fftSize * sampleRate;
            fx2[j] = static_cast<double>(j) / fftSize * sampleRate;
        }
        for (int i = 0; i < f0Len; ++i) {
            for (int j = 0; j < bins; ++j) {
                s1[j] = std::log(std::max(1e-16, spec[i][j]));
            }
            interp1(fx1.data(), s1.data(), bins, fx2.data(), bins, s2.data());
            for (int j = 0; j < bins; ++j) {
                spec[i][j] = std::exp(s2[j]);
            }
            if (formantRatio < 1.0) {
                const int cut = std::min(bins - 1, std::max(1, static_cast<int>(fftSize * 0.5 * formantRatio)));
                for (int j = cut; j < bins; ++j) {
                    const double t = static_cast<double>(j - cut) / std::max(1, bins - cut);
                    spec[i][j] = spec[i][cut - 1] * std::exp(-3.0 * t);
                }
            }
        }
    }

    std::vector<double> y(numSamples, 0.0);
    Synthesis(refinedF0.data(), f0Len, spec.data(), ap.data(), fftSize, dioOpt.frame_period, sampleRate, numSamples, y.data());

    cleanAndNormalize(y, sampleRate, false);
    return y;
}

}  // namespace

extern "C" {

AAC_EXPORT int32_t aac_process_float_pcm_to_wav(
    const float* samples,
    int32_t numSamples,
    int32_t sampleRate,
    const char* outWavPath,
    float targetF0Hz,
    float formantSemitones
) {
    if (!samples || numSamples <= 0 || sampleRate <= 0 || !outWavPath) return -1;
    std::vector<double> dSamples(numSamples);
    for (int32_t i = 0; i < numSamples; ++i) {
        dSamples[i] = static_cast<double>(samples[i]);
    }
    std::vector<double> out = processPcmSamples(
        dSamples.data(), numSamples, sampleRate, targetF0Hz, formantSemitones
    );
    return writeWav(outWavPath, out, sampleRate) ? 0 : -2;
}

AAC_EXPORT int32_t aac_process_wav_file(
    const char* inWavPath,
    const char* outWavPath,
    float targetF0Hz,
    float formantSemitones
) {
    if (!inWavPath || !outWavPath) return -1;
    WavData wav;
    if (!readWav(inWavPath, wav)) return -2;
    std::vector<double> out = processPcmSamples(
        wav.samples.data(),
        static_cast<int32_t>(wav.samples.size()),
        wav.sampleRate,
        targetF0Hz,
        formantSemitones
    );
    return writeWav(outWavPath, out, wav.sampleRate) ? 0 : -3;
}

#ifdef __ANDROID__
JNIEXPORT jint JNICALL
Java_com_example_simple_1aac_1app_AacVoiceBridge_nativeProcessVoiceWav(
    JNIEnv* env,
    jobject /* thiz */,
    jstring inPath,
    jstring outPath,
    jfloat targetF0Hz,
    jfloat formantSemitones
) {
    if (!inPath || !outPath) return -1;
    const char* inC = env->GetStringUTFChars(inPath, nullptr);
    const char* outC = env->GetStringUTFChars(outPath, nullptr);
    const int32_t rc = aac_process_wav_file(inC, outC, targetF0Hz, formantSemitones);
    env->ReleaseStringUTFChars(inPath, inC);
    env->ReleaseStringUTFChars(outPath, outC);
    return static_cast<jint>(rc);
}
#endif

}  // extern "C"
