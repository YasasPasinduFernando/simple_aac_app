package com.example.simple_aac_app

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import java.io.File
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class AacVoiceBridge(context: Context) {
    private val appContext = context.applicationContext
    private var tts: TextToSpeech? = null
    private val ttsLock = Any()

    external fun nativeProcessVoiceWav(
        inPath: String,
        outPath: String,
        targetF0Hz: Float,
        formantSemitones: Float
    ): Int

    fun processVoiceWav(
        inPath: String,
        outPath: String,
        targetF0Hz: Float,
        formantSemitones: Float
    ): Boolean {
        val outFile = File(outPath)
        outFile.parentFile?.mkdirs()
        return nativeProcessVoiceWav(inPath, outPath, targetF0Hz, formantSemitones) == 0 &&
            outFile.exists() &&
            outFile.length() > 44
    }

    fun synthesizeCleanFallbackWav(
        text: String,
        localeTag: String,
        outPath: String,
        targetF0Hz: Float,
        formantSemitones: Float,
        speechRate: Float
    ): Boolean {
        val engine = ensureSystemTts() ?: return false
        val utteranceId = "aac_${UUID.randomUUID()}"
        val rawFile = File(appContext.cacheDir, "$utteranceId.raw.wav")
        val outFile = File(outPath)
        outFile.parentFile?.mkdirs()

        val doneLatch = CountDownLatch(1)
        val success = AtomicBoolean(false)
        pendingLatches[utteranceId] = Pair(doneLatch, success)

        try {
            synchronized(ttsLock) {
                selectCleanVoiceLocked(engine, localeTag)
                // Always synthesize at neutral 1.0 pitch so OEM pitch-shifting cannot introduce whisper artifacts.
                engine.setPitch(1.0f)
                engine.setSpeechRate(speechRate.coerceIn(0.65f, 1.35f))
                val rc = engine.synthesizeToFile(text, Bundle(), rawFile, utteranceId)
                if (rc != TextToSpeech.SUCCESS) {
                    return false
                }
            }
            if (!doneLatch.await(8, TimeUnit.SECONDS) || !success.get()) {
                return false
            }
            if (!rawFile.exists() || rawFile.length() <= 44) {
                return false
            }
            return nativeProcessVoiceWav(
                rawFile.absolutePath,
                outPath,
                targetF0Hz,
                formantSemitones
            ) == 0 && outFile.exists() && outFile.length() > 44
        } finally {
            pendingLatches.remove(utteranceId)
            rawFile.delete()
        }
    }

    private fun ensureSystemTts(): TextToSpeech? {
        synchronized(ttsLock) {
            tts?.let { return it }
            val created = initEngineWithPackage("com.google.android.tts")
                ?: initEngineWithPackage(null)
            created?.setOnUtteranceProgressListener(progressListener)
            tts = created
            return created
        }
    }

    private fun initEngineWithPackage(pkg: String?): TextToSpeech? {
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
        latch.await(4, TimeUnit.SECONDS)
        if (status == TextToSpeech.SUCCESS) {
            return candidate
        }
        candidate.shutdown()
        return null
    }

    private fun selectCleanVoiceLocked(engine: TextToSpeech, localeTag: String) {
        val targetLocale = Locale.forLanguageTag(localeTag)
        val langPrefix = targetLocale.language.lowercase(Locale.ROOT)
        val res = engine.setLanguage(targetLocale)
        if (res == TextToSpeech.LANG_MISSING_DATA || res == TextToSpeech.LANG_NOT_SUPPORTED) {
            engine.setLanguage(Locale(langPrefix))
        }
        val voices = try {
            engine.voices
        } catch (_: Exception) {
            null
        } ?: return

        var bestVoice: Voice? = null
        var bestScore = Int.MIN_VALUE
        for (v in voices) {
            val vLang = v.locale?.language?.lowercase(Locale.ROOT) ?: continue
            if (vLang != langPrefix) continue
            if (v.isNetworkConnectionRequired) continue
            var score = v.quality
            val nameLower = v.name.lowercase(Locale.ROOT)
            if (nameLower.contains("-local") || nameLower.contains("-x-")) score += 40
            if (v.locale.toLanguageTag().equals(localeTag, ignoreCase = true)) score += 30
            if (score > bestScore) {
                bestScore = score
                bestVoice = v
            }
        }
        if (bestVoice != null) {
            engine.voice = bestVoice
        }
    }

    fun shutdown() {
        synchronized(ttsLock) {
            tts?.stop()
            tts?.shutdown()
            tts = null
        }
        pendingLatches.clear()
    }

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

    companion object {
        init {
            System.loadLibrary("aac_voice_dsp")
        }
    }
}
