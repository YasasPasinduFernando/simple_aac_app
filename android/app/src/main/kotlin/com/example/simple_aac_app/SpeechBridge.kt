package com.example.simple_aac_app

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Clean Android system TTS bridge for unified SpeechEngine.
 *
 * Inspects installed offline voices explicitly, verifies non-silent WAV
 * synthesis, stitches multilingual segments cleanly with RMS matching,
 * and opens Android TTS voice data installation when a language pack is missing.
 */
class SpeechBridge(context: Context) {
    private val appContext = context.applicationContext
    private var tts: TextToSpeech? = null
    private val ttsLock = Any()
    private val pendingLatches = ConcurrentHashMap<String, Pair<CountDownLatch, AtomicBoolean>>()

    private val progressListener = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {}
        override fun onDone(utteranceId: String?) {
            utteranceId?.let { id ->
                pendingLatches[id]?.let { (latch, ok) ->
                    ok.set(true)
                    latch.countDown()
                }
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) {
            utteranceId?.let { id ->
                pendingLatches[id]?.let { (latch, ok) ->
                    ok.set(false)
                    latch.countDown()
                }
            }
        }

        override fun onError(utteranceId: String?, errorCode: Int) {
            onError(utteranceId)
        }
    }

    private fun ensureEngine(preferredPackage: String? = null): TextToSpeech? {
        synchronized(ttsLock) {
            if (preferredPackage == null) {
                tts?.let { return it }
            }
            val created = if (preferredPackage != null) {
                initEngine(preferredPackage)
            } else {
                initEngine("com.google.android.tts") ?: initEngine(null)
            }
            created?.setOnUtteranceProgressListener(progressListener)
            if (preferredPackage == null) {
                tts = created
            }
            return created
        }
    }

    private fun initEngine(pkg: String?): TextToSpeech? {
        val latch = CountDownLatch(1)
        var status = TextToSpeech.ERROR
        val listener = TextToSpeech.OnInitListener { s ->
            status = s
            latch.countDown()
        }
        val candidate = try {
            if (pkg != null) TextToSpeech(appContext, listener, pkg)
            else TextToSpeech(appContext, listener)
        } catch (_: Exception) {
            return null
        }
        latch.await(5, TimeUnit.SECONDS)
        if (status == TextToSpeech.SUCCESS) {
            return candidate
        }
        try {
            candidate.shutdown()
        } catch (_: Exception) {
        }
        return null
    }

    fun probeCapabilities(): Map<String, Any?> {
        val engine = ensureEngine()
        val defaultPkg = try {
            engine?.defaultEngine
        } catch (_: Exception) {
            null
        }
        val engineInfos = try {
            engine?.engines?.map { info ->
                mapOf("name" to info.name, "label" to info.label)
            } ?: emptyList()
        } catch (_: Exception) {
            emptyList<Map<String, String>>()
        }

        val languages = mutableMapOf<String, Map<String, Any?>>()
        val targets = mapOf("en" to "en-US", "si" to "si-LK", "ta" to "ta-IN")
        val allVoices = try {
            engine?.voices ?: emptySet()
        } catch (_: Exception) {
            emptySet()
        }

        for ((code, tag) in targets) {
            val locale = Locale.forLanguageTag(tag)
            val availability = if (engine != null) {
                synchronized(ttsLock) {
                    try {
                        engine.isLanguageAvailable(locale)
                    } catch (_: Exception) {
                        TextToSpeech.LANG_NOT_SUPPORTED
                    }
                }
            } else {
                TextToSpeech.LANG_NOT_SUPPORTED
            }

            val matchingVoices = allVoices
                .filter { v ->
                    v.locale?.language?.equals(code, ignoreCase = true) == true
                }
                .map { v ->
                    val notInstalled =
                        v.features?.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) == true
                    mapOf(
                        "name" to v.name,
                        "locale" to (v.locale?.toLanguageTag() ?: ""),
                        "quality" to v.quality,
                        "requiresNetwork" to v.isNetworkConnectionRequired,
                        "notInstalled" to notInstalled,
                        "features" to (v.features?.toList() ?: emptyList()),
                    )
                }

            val installedOfflineCount = matchingVoices.count {
                it["requiresNetwork"] == false && it["notInstalled"] == false
            }
            val hasOfflineVoice = installedOfflineCount > 0 ||
                availability >= TextToSpeech.LANG_AVAILABLE

            languages[code] = mapOf(
                "localeTag" to tag,
                "availabilityCode" to availability,
                "hasOfflineVoice" to hasOfflineVoice,
                "voiceCount" to matchingVoices.size,
                "offlineVoiceCount" to installedOfflineCount,
                "voices" to matchingVoices,
            )
        }

        return mapOf(
            "initialized" to (engine != null),
            "defaultEngine" to defaultPkg,
            "engines" to engineInfos,
            "languages" to languages,
        )
    }

    /**
     * Synthesizes one or more language-tagged text segments into a single clean,
     * RMS-matched, verified non-silent 16-bit PCM WAV file using offline Android voices.
     *
     * Returns status map:
     * - ok: Boolean
     * - status: "spoken" | "missing_language_data" | "engine_unavailable" | "synthesis_failed" | "empty_audio"
     * - path: String?
     * - missingLanguages: List<String>
     * - rms: Double
     * - durationMs: Int
     */
    fun synthesizeSegmentsToWav(
        segments: List<Map<String, String>>,
        outputPath: String,
        speechRate: Float = 0.96f,
        allowNetworkVoice: Boolean = false,
    ): Map<String, Any?> {
        val engine = ensureEngine()
            ?: return mapOf("ok" to false, "status" to "engine_unavailable")

        if (segments.isEmpty()) {
            return mapOf("ok" to false, "status" to "empty_audio")
        }

        val parsedSegments = mutableListOf<WavPcm>()
        val missingLangs = mutableListOf<String>()

        for ((idx, seg) in segments.withIndex()) {
            val text = seg["text"]?.trim().orEmpty()
            val lang = seg["lang"]?.trim().orEmpty().ifEmpty { "en" }
            if (text.isEmpty()) continue

            val localeTag = when (lang) {
                "si" -> "si-LK"
                "ta" -> "ta-IN"
                else -> "en-US"
            }

            val segFile = File(appContext.cacheDir, "sb_${UUID.randomUUID()}_$idx.wav")
            try {
                val res = synthesizeSingleToFileLocked(
                    engine = engine,
                    text = text,
                    langCode = lang,
                    localeTag = localeTag,
                    outFile = segFile,
                    speechRate = speechRate,
                    allowNetworkVoice = allowNetworkVoice,
                )
                val status = res["status"] as String
                if (status != "ok") {
                    if (status == "missing_language_data") {
                        missingLangs.add(lang)
                    }
                    return mapOf(
                        "ok" to false,
                        "status" to status,
                        "missingLanguages" to missingLangs,
                        "failedSegmentText" to text,
                        "failedSegmentLang" to lang,
                    )
                }
                val pcm = readWavPcm(segFile)
                if (pcm == null || !isAudiblePcm(pcm)) {
                    return mapOf(
                        "ok" to false,
                        "status" to "empty_audio",
                        "failedSegmentText" to text,
                        "failedSegmentLang" to lang,
                    )
                }
                parsedSegments.add(trimSilenceAndNormalize(pcm, targetRms = 0.16))
            } finally {
                segFile.delete()
            }
        }

        if (parsedSegments.isEmpty()) {
            return mapOf("ok" to false, "status" to "empty_audio")
        }

        val stitched = stitchSegments(parsedSegments, gapMs = 45)
        val outFile = File(outputPath)
        outFile.parentFile?.mkdirs()
        if (!writeWavPcm(outFile, stitched)) {
            return mapOf("ok" to false, "status" to "synthesis_failed")
        }

        val rms = computeRms(stitched.samples)
        val durationMs = ((stitched.samples.size.toDouble() / stitched.sampleRate) * 1000.0).toInt()
        return mapOf(
            "ok" to true,
            "status" to "ok",
            "path" to outFile.absolutePath,
            "rms" to rms,
            "durationMs" to durationMs,
            "sampleRate" to stitched.sampleRate,
        )
    }

    private fun synthesizeSingleToFileLocked(
        engine: TextToSpeech,
        text: String,
        langCode: String,
        localeTag: String,
        outFile: File,
        speechRate: Float,
        allowNetworkVoice: Boolean,
    ): Map<String, Any?> {
        val utteranceId = "aac_sp_${UUID.randomUUID()}"
        val latch = CountDownLatch(1)
        val success = AtomicBoolean(false)
        pendingLatches[utteranceId] = Pair(latch, success)

        try {
            synchronized(ttsLock) {
                val selected = selectBestVoiceLocked(
                    engine = engine,
                    langCode = langCode,
                    localeTag = localeTag,
                    allowNetworkVoice = allowNetworkVoice,
                )
                if (!selected) {
                    return mapOf("status" to "missing_language_data")
                }
                engine.setPitch(1.0f)
                engine.setSpeechRate(speechRate.coerceIn(0.65f, 1.35f))
                val params = Bundle().apply {
                    putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
                }
                val rc = engine.synthesizeToFile(text, params, outFile, utteranceId)
                if (rc != TextToSpeech.SUCCESS) {
                    return mapOf("status" to "synthesis_failed")
                }
            }
            if (!latch.await(10, TimeUnit.SECONDS) || !success.get()) {
                return mapOf("status" to "synthesis_failed")
            }
            if (!outFile.exists() || outFile.length() <= 44) {
                return mapOf("status" to "empty_audio")
            }
            return mapOf("status" to "ok")
        } finally {
            pendingLatches.remove(utteranceId)
        }
    }

    private fun selectBestVoiceLocked(
        engine: TextToSpeech,
        langCode: String,
        localeTag: String,
        allowNetworkVoice: Boolean,
    ): Boolean {
        val targetLocale = Locale.forLanguageTag(localeTag)
        val voices = try {
            engine.voices
        } catch (_: Exception) {
            null
        }

        if (voices != null && voices.isNotEmpty()) {
            var bestOffline: Voice? = null
            var bestOfflineScore = Int.MIN_VALUE
            var bestAny: Voice? = null
            var bestAnyScore = Int.MIN_VALUE

            for (v in voices) {
                val vLang = v.locale?.language?.lowercase(Locale.ROOT) ?: continue
                if (vLang != langCode.lowercase(Locale.ROOT)) continue
                val notInstalled =
                    v.features?.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED) == true
                if (notInstalled) continue

                var score = v.quality
                val nameLower = v.name.lowercase(Locale.ROOT)
                if (!v.isNetworkConnectionRequired) score += 200
                if (nameLower.contains("-local") || nameLower.contains("-x-")) score += 40
                if (v.locale.toLanguageTag().equals(localeTag, ignoreCase = true)) score += 30
                // Slight preference for natural female/default neural voice names over deprecated legacy.
                if (v.quality >= Voice.QUALITY_HIGH) score += 20

                if (!v.isNetworkConnectionRequired && score > bestOfflineScore) {
                    bestOfflineScore = score
                    bestOffline = v
                }
                if (score > bestAnyScore) {
                    bestAnyScore = score
                    bestAny = v
                }
            }

            val chosen = bestOffline ?: (if (allowNetworkVoice) bestAny else null)
            if (chosen != null) {
                engine.voice = chosen
                return true
            }
        }

        val avail = try {
            engine.isLanguageAvailable(targetLocale)
        } catch (_: Exception) {
            TextToSpeech.LANG_NOT_SUPPORTED
        }
        if (avail == TextToSpeech.LANG_MISSING_DATA || avail == TextToSpeech.LANG_NOT_SUPPORTED) {
            val langOnlyAvail = try {
                engine.isLanguageAvailable(Locale(langCode))
            } catch (_: Exception) {
                TextToSpeech.LANG_NOT_SUPPORTED
            }
            if (langOnlyAvail == TextToSpeech.LANG_MISSING_DATA || langOnlyAvail == TextToSpeech.LANG_NOT_SUPPORTED) {
                return false
            }
            engine.setLanguage(Locale(langCode))
            return true
        }
        engine.setLanguage(targetLocale)
        return true
    }

    fun openTtsInstaller(): Boolean {
        return try {
            val installIntent = Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            appContext.startActivity(installIntent)
            true
        } catch (_: Exception) {
            try {
                val settingsIntent = Intent("com.android.settings.TTS_SETTINGS").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                appContext.startActivity(settingsIntent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    fun shutdown() {
        synchronized(ttsLock) {
            try {
                tts?.stop()
                tts?.shutdown()
            } catch (_: Exception) {
            }
            tts = null
        }
        pendingLatches.clear()
    }

    // -------------------------------------------------------------------------
    // Minimal 16-bit PCM WAV inspection, silence trimming & segment stitching
    // -------------------------------------------------------------------------

    private class WavPcm(val sampleRate: Int, val samples: FloatArray)

    private fun readWavPcm(file: File): WavPcm? {
        val bytes = file.readBytes()
        if (bytes.size < 44) return null
        val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        if (String(bytes, 0, 4) != "RIFF" || String(bytes, 8, 4) != "WAVE") return null

        var pos = 12
        var channels = 1
        var sampleRate = 22050
        var bitsPerSample = 16
        var audioFormat = 1
        var dataOffset = -1
        var dataSize = 0

        while (pos + 8 <= bytes.size) {
            val id = String(bytes, pos, 4)
            val size = buf.getInt(pos + 4)
            val bodyStart = pos + 8
            if (id == "fmt " && size >= 16 && bodyStart + 16 <= bytes.size) {
                audioFormat = buf.getShort(bodyStart).toInt() and 0xFFFF
                channels = max(1, buf.getShort(bodyStart + 2).toInt() and 0xFFFF)
                sampleRate = max(8000, buf.getInt(bodyStart + 4))
                bitsPerSample = buf.getShort(bodyStart + 14).toInt() and 0xFFFF
            } else if (id == "data" && bodyStart + size <= bytes.size) {
                dataOffset = bodyStart
                dataSize = size
                break
            }
            pos = bodyStart + size + (size and 1)
        }

        if (dataOffset < 0 || dataSize <= 0 || audioFormat != 1 || bitsPerSample != 16) {
            return null
        }

        val frameCount = dataSize / (2 * channels)
        if (frameCount <= 0) return null
        val out = FloatArray(frameCount)
        var offset = dataOffset
        for (i in 0 until frameCount) {
            var sum = 0f
            for (c in 0 until channels) {
                val s = buf.getShort(offset).toFloat() / 32768f
                sum += s
                offset += 2
            }
            out[i] = sum / channels
        }
        return WavPcm(sampleRate, out)
    }

    private fun isAudiblePcm(wav: WavPcm): Boolean {
        var peak = 0f
        for (s in wav.samples) {
            val a = abs(s)
            if (a > peak) peak = a
        }
        return peak >= 0.002f && wav.samples.size >= wav.sampleRate / 25
    }

    private fun computeRms(samples: FloatArray): Double {
        if (samples.isEmpty()) return 0.0
        var sumSq = 0.0
        for (s in samples) {
            sumSq += s.toDouble() * s.toDouble()
        }
        return sqrt(sumSq / samples.size)
    }

    private fun trimSilenceAndNormalize(wav: WavPcm, targetRms: Double): WavPcm {
        val x = wav.samples
        var peak = 0f
        for (v in x) peak = max(peak, abs(v))
        if (peak < 1e-4f) return wav

        val thresh = peak * 0.015f
        var first = 0
        var last = x.size
        while (first < x.size && abs(x[first]) < thresh) first++
        while (last > first && abs(x[last - 1]) < thresh) last--

        val pad = min(first, (0.015f * wav.sampleRate).toInt())
        first -= pad
        last = min(x.size, last + (0.025f * wav.sampleRate).toInt())
        val trimmed = x.copyOfRange(first, last)

        val curRms = computeRms(trimmed)
        if (curRms > 1e-4) {
            val gain = min(4.5, targetRms / curRms).toFloat()
            for (i in trimmed.indices) {
                trimmed[i] = (trimmed[i] * gain).coerceIn(-0.90f, 0.90f)
            }
        }

        val fade = min(trimmed.size / 6, (0.004f * wav.sampleRate).toInt())
        for (i in 0 until fade) {
            val g = i.toFloat() / fade
            trimmed[i] *= g
            trimmed[trimmed.size - 1 - i] *= g
        }
        return WavPcm(wav.sampleRate, trimmed)
    }

    private fun resampleLinear(samples: FloatArray, srcRate: Int, dstRate: Int): FloatArray {
        if (srcRate == dstRate || samples.isEmpty()) return samples
        val ratio = dstRate.toDouble() / srcRate.toDouble()
        val outLen = max(1, (samples.size * ratio).toInt())
        val out = FloatArray(outLen)
        for (i in 0 until outLen) {
            val srcPos = i.toDouble() / ratio
            val idx0 = min(samples.size - 1, srcPos.toInt())
            val idx1 = min(samples.size - 1, idx0 + 1)
            val frac = (srcPos - idx0).toFloat()
            out[i] = samples[idx0] * (1f - frac) + samples[idx1] * frac
        }
        return out
    }

    private fun stitchSegments(parts: List<WavPcm>, gapMs: Int): WavPcm {
        val targetRate = parts.first().sampleRate
        val gapSamples = max(0, (targetRate * gapMs) / 1000)
        val resampled = parts.map {
            if (it.sampleRate == targetRate) it.samples else resampleLinear(it.samples, it.sampleRate, targetRate)
        }
        val totalLen = resampled.sumOf { it.size } + gapSamples * max(0, resampled.size - 1)
        val out = FloatArray(totalLen)
        var cursor = 0
        for ((i, arr) in resampled.withIndex()) {
            arr.copyInto(out, cursor)
            cursor += arr.size
            if (i + 1 < resampled.size) {
                cursor += gapSamples
            }
        }
        return WavPcm(targetRate, out)
    }

    private fun writeWavPcm(file: File, wav: WavPcm): Boolean {
        val dataBytes = wav.samples.size * 2
        val riffSize = 36 + dataBytes
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray())
        header.putInt(riffSize)
        header.put("WAVEfmt ".toByteArray())
        header.putInt(16)
        header.putShort(1.toShort())
        header.putShort(1.toShort())
        header.putInt(wav.sampleRate)
        header.putInt(wav.sampleRate * 2)
        header.putShort(2.toShort())
        header.putShort(16.toShort())
        header.put("data".toByteArray())
        header.putInt(dataBytes)

        val pcmBytes = ByteBuffer.allocate(dataBytes).order(ByteOrder.LITTLE_ENDIAN)
        for (s in wav.samples) {
            val clamped = max(-1f, min(1f, s))
            pcmBytes.putShort((clamped * 32767f).toInt().toShort())
        }

        FileOutputStream(file).use { fos ->
            fos.write(header.array())
            fos.write(pcmBytes.array())
            fos.flush()
        }
        return file.exists() && file.length() > 44
    }
}
