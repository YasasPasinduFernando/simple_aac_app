#include <algorithm>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <string>
#include <vector>

#ifdef __ANDROID__
#include <jni.h>
#endif

#include "signalsmith-stretch/signalsmith-stretch.h"

#define AAC_EXPORT __attribute__((visibility("default")))

namespace {

constexpr float kPi = 3.14159265358979323846f;

struct WavData {
    int sampleRate = 22050;
    std::vector<float> samples;
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
            float sum = 0.0f;
            for (int c = 0; c < channels; ++c) {
                sum += static_cast<float>(p[i * channels + c]) / 32768.0f;
            }
            out.samples[i] = sum / static_cast<float>(channels);
        }
        return !out.samples.empty();
    }

    if (audioFormat == 3 && bitsPerSample == 32) {
        const size_t n = rawData.size() / (4 * channels);
        out.samples.resize(n);
        const float* p = reinterpret_cast<const float*>(rawData.data());
        for (size_t i = 0; i < n; ++i) {
            float sum = 0.0f;
            for (int c = 0; c < channels; ++c) {
                sum += p[i * channels + c];
            }
            out.samples[i] = sum / static_cast<float>(channels);
        }
        return !out.samples.empty();
    }

    return false;
}

bool writeWav(const std::string& path, const std::vector<float>& samples, int sr) {
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
        const float clamped = std::max(-1.0f, std::min(1.0f, samples[i]));
        pcm[i] = static_cast<int16_t>(std::lrintf(clamped * 32767.0f));
    }
    f.write(reinterpret_cast<const char*>(pcm.data()), dataBytes);
    f.flush();
    return f.good();
}

// Fast normalized-square-difference pitch estimator over voiced speech frames.
float estimateMedianF0(const std::vector<float>& x, int sr) {
    const int frameLen = std::max(256, static_cast<int>(0.030 * sr));
    const int hop = std::max(64, static_cast<int>(0.010 * sr));
    const int minLag = std::max(2, static_cast<int>(sr / 450.0));
    const int maxLag = std::min(frameLen - 2, static_cast<int>(sr / 65.0));
    if (static_cast<int>(x.size()) < frameLen || minLag >= maxLag) return 200.0f;

    double gEnergy = 0.0;
    for (float v : x) gEnergy += static_cast<double>(v) * v;
    const double gRms = std::sqrt(gEnergy / static_cast<double>(x.size()));
    if (gRms < 1e-5) return 200.0f;

    std::vector<float> f0s;
    for (int start = 0; start + frameLen <= static_cast<int>(x.size()); start += hop) {
        double fe = 0.0;
        for (int i = 0; i < frameLen; ++i) {
            const double v = x[start + i];
            fe += v * v;
        }
        if (std::sqrt(fe / frameLen) < gRms * 0.35) continue;

        double bestNorm = -1.0;
        int bestLag = -1;
        for (int lag = minLag; lag <= maxLag; ++lag) {
            double num = 0.0;
            double denA = 0.0;
            double denB = 0.0;
            const int n = frameLen - lag;
            for (int i = 0; i < n; ++i) {
                const double a = x[start + i];
                const double b = x[start + i + lag];
                num += a * b;
                denA += a * a;
                denB += b * b;
            }
            const double den = std::sqrt(denA * denB);
            if (den < 1e-12) continue;
            const double nsdf = num / den;
            if (nsdf > bestNorm) {
                bestNorm = nsdf;
                bestLag = lag;
            }
        }
        if (bestNorm > 0.55 && bestLag > 0) {
            f0s.push_back(static_cast<float>(sr) / static_cast<float>(bestLag));
        }
    }

    if (f0s.empty()) return 200.0f;
    std::sort(f0s.begin(), f0s.end());
    return f0s[f0s.size() / 2];
}

struct Biquad {
    float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f, a1 = 0.0f, a2 = 0.0f;
    float z1 = 0.0f, z2 = 0.0f;

    void setHighpass(float fc, float sr, float q = 0.707f) {
        const float w0 = 2.0f * kPi * std::min(fc, sr * 0.45f) / sr;
        const float cs = std::cos(w0);
        const float sn = std::sin(w0);
        const float alpha = sn / (2.0f * q);
        const float a0 = 1.0f + alpha;
        b0 = (1.0f + cs) * 0.5f / a0;
        b1 = -(1.0f + cs) / a0;
        b2 = b0;
        a1 = (-2.0f * cs) / a0;
        a2 = (1.0f - alpha) / a0;
        z1 = z2 = 0.0f;
    }

    void setLowShelf(float fc, float sr, float gainDb) {
        const float A = std::pow(10.0f, gainDb / 40.0f);
        const float w0 = 2.0f * kPi * std::min(fc, sr * 0.45f) / sr;
        const float cs = std::cos(w0);
        const float sn = std::sin(w0);
        const float beta = sn * std::sqrt((A * A + 1.0f) - (A - 1.0f) * (A - 1.0f));
        const float a0 = (A + 1.0f) + (A - 1.0f) * cs + beta;
        b0 = A * ((A + 1.0f) - (A - 1.0f) * cs + beta) / a0;
        b1 = 2.0f * A * ((A - 1.0f) - (A + 1.0f) * cs) / a0;
        b2 = A * ((A + 1.0f) - (A - 1.0f) * cs - beta) / a0;
        a1 = -2.0f * ((A - 1.0f) + (A + 1.0f) * cs) / a0;
        a2 = ((A + 1.0f) + (A - 1.0f) * cs - beta) / a0;
        z1 = z2 = 0.0f;
    }

    inline float tick(float x) {
        const float y = b0 * x + z1;
        z1 = b1 * x - a1 * y + z2;
        z2 = b2 * x - a2 * y;
        return y;
    }
};

void cleanAndNormalize(std::vector<float>& y, int sr) {
    if (y.empty() || sr <= 0) return;

    Biquad hp;
    hp.setHighpass(75.0f, static_cast<float>(sr));
    for (float& v : y) v = hp.tick(v);

    float peak = 0.0f;
    for (float v : y) peak = std::max(peak, std::abs(v));
    if (peak < 1e-5f) return;

    const float thresh = peak * 0.015f;
    size_t first = 0;
    size_t last = y.size();
    while (first < y.size() && std::abs(y[first]) < thresh) ++first;
    while (last > first && std::abs(y[last - 1]) < thresh) --last;

    const size_t leadPad = std::min<size_t>(static_cast<size_t>(0.025 * sr), first);
    first -= leadPad;
    last = std::min(y.size(), last + static_cast<size_t>(0.040 * sr));
    if (last > first) {
        y = std::vector<float>(y.begin() + first, y.begin() + last);
    }

    peak = 0.0f;
    for (float v : y) peak = std::max(peak, std::abs(v));
    if (peak > 1e-5f) {
        const float gain = std::min(12.0f, 0.84f / peak);
        for (float& v : y) v = std::tanh(v * gain);
        float newPeak = 0.0f;
        for (float v : y) newPeak = std::max(newPeak, std::abs(v));
        if (newPeak > 0.85f) {
            const float rescale = 0.84f / newPeak;
            for (float& v : y) v *= rescale;
        }
    }

    const size_t fade = std::min<size_t>(static_cast<size_t>(0.005 * sr), y.size() / 4);
    for (size_t i = 0; i < fade; ++i) {
        const float g = static_cast<float>(i) / static_cast<float>(fade);
        y[i] *= g;
        y[y.size() - 1 - i] *= g;
    }
}

std::vector<float> processPcmSamples(
    const float* samples,
    int32_t numSamples,
    int32_t sampleRate,
    float targetF0Hz,
    float formantSemitones
) {
    std::vector<float> in(samples, samples + numSamples);
    if (targetF0Hz <= 0.0f && std::abs(formantSemitones) < 0.05f) {
        cleanAndNormalize(in, sampleRate);
        return in;
    }

    const float srcF0 = estimateMedianF0(in, sampleRate);
    float pitchDeltaSt = 0.0f;
    if (targetF0Hz > 0.0f) {
        pitchDeltaSt = 12.0f * std::log2(std::max(60.0f, targetF0Hz) / std::max(60.0f, srcF0));
        pitchDeltaSt = std::max(-14.0f, std::min(12.0f, pitchDeltaSt));
    }

    signalsmith::stretch::SignalsmithStretch<float> stretch;
    stretch.presetDefault(1, static_cast<float>(sampleRate));
    stretch.setTransposeSemitones(pitchDeltaSt, 0.0f);
    stretch.setFormantSemitones(formantSemitones, false);
    stretch.setFormantBase(srcF0 / static_cast<float>(sampleRate));

    const int totalLat = stretch.inputLatency() + stretch.outputLatency();
    std::vector<float> padded(in.size() + static_cast<size_t>(totalLat), 0.0f);
    std::copy(in.begin(), in.end(), padded.begin());

    std::vector<float> rawOut(padded.size(), 0.0f);
    const float* inPtrs[1] = { padded.data() };
    float* outPtrs[1] = { rawOut.data() };
    stretch.process(inPtrs, static_cast<int>(padded.size()), outPtrs, static_cast<int>(rawOut.size()));

    // Skip sample-exact STFT latency (inputLatency + outputLatency) so y[i] aligns with in[i].
    const size_t skip = std::min<size_t>(static_cast<size_t>(totalLat), rawOut.size());
    std::vector<float> y(rawOut.begin() + skip, rawOut.end());

    // Preserve unvoiced sibilant/consonant clarity (>4.4 kHz) & chest warmth when shifting down strongly.
    if (pitchDeltaSt < -4.0f) {
        Biquad airHp;
        airHp.setHighpass(4400.0f, static_cast<float>(sampleRate), 0.707f);
        Biquad chestShelf;
        chestShelf.setLowShelf(160.0f, static_cast<float>(sampleRate), 2.5f);
        const size_t n = std::min(y.size(), in.size());
        for (size_t i = 0; i < n; ++i) {
            y[i] = chestShelf.tick(y[i]) + 0.55f * airHp.tick(in[i]);
        }
    }

    cleanAndNormalize(y, sampleRate);
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
    std::vector<float> out = processPcmSamples(
        samples, numSamples, sampleRate, targetF0Hz, formantSemitones
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
    std::vector<float> out = processPcmSamples(
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
