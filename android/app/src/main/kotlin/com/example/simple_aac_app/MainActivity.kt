package com.example.simple_aac_app

import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabel
import com.google.mlkit.vision.label.ImageLabeler
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.objects.DetectedObject
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.ObjectDetector
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val channelName = "aac_backup"
    private val visionChannelName = "aac_vision"
    private val voiceChannelName = "aac_voice"
    private val visionExecutor = Executors.newSingleThreadExecutor()
    private val voiceExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var imageLabeler: ImageLabeler? = null
    private var objectDetector: ObjectDetector? = null
    private var voiceBridge: AacVoiceBridge? = null

    private fun getLabeler(): ImageLabeler {
        return imageLabeler ?: ImageLabeling.getClient(
            ImageLabelerOptions.Builder()
                .setConfidenceThreshold(0.52f)
                .build()
        ).also { imageLabeler = it }
    }

    private fun getDetector(): ObjectDetector {
        return objectDetector ?: ObjectDetection.getClient(
            ObjectDetectorOptions.Builder()
                .setDetectorMode(ObjectDetectorOptions.SINGLE_IMAGE_MODE)
                .enableMultipleObjects()
                .enableClassification()
                .build()
        ).also { objectDetector = it }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val fileName = call.argument<String>("fileName") ?: "aac_backup.zip"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("NO_BYTES", "No bytes provided", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val savedPath = saveToDownloads(fileName, bytes)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else if (call.method == "getSdkVersion") {
                    result.success(Build.VERSION.SDK_INT)
                } else if (call.method == "openExternalUrl") {
                    val rawUrl = call.argument<String>("url")
                    if (rawUrl == null || (!rawUrl.startsWith("https://") && !rawUrl.startsWith("http://"))) {
                        result.error("INVALID_URL", "Invalid HTTP/HTTPS URL", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(rawUrl))
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, visionChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "analyzeImage") {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("NO_PATH", "Image path is required", null)
                        return@setMethodCallHandler
                    }
                    visionExecutor.execute {
                        try {
                            val response = analyzeImageOffline(path)
                            mainHandler.post { result.success(response) }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error("ANALYSIS_FAILED", e.message ?: "Offline vision analysis failed", null)
                            }
                        }
                    }
                } else if (call.method == "probeVideoDuration") {
                    val inputPath = call.argument<String>("inputPath")
                    if (inputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "inputPath is required", null)
                        return@setMethodCallHandler
                    }
                    visionExecutor.execute {
                        try {
                            val durationMs = VideoGifEncoder.probeDurationMs(applicationContext, inputPath)
                            mainHandler.post { result.success(durationMs) }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error("PROBE_FAILED", e.message ?: "Could not inspect video", null)
                            }
                        }
                    }
                } else if (call.method == "convertVideoToGif") {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val trimToLimit = call.argument<Boolean>("trimToLimit") ?: false
                    if (inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                        return@setMethodCallHandler
                    }
                    visionExecutor.execute {
                        try {
                            val res = VideoGifEncoder.convertVideoToGif(
                                applicationContext,
                                inputPath,
                                outputPath,
                                trimToLimit
                            )
                            mainHandler.post {
                                result.success(
                                    mapOf(
                                        "outputPath" to res.outputPath,
                                        "durationMs" to res.durationMs,
                                        "encodedDurationMs" to res.encodedDurationMs,
                                        "trimmed" to res.trimmed,
                                        "frameCount" to res.frameCount,
                                        "width" to res.width,
                                        "height" to res.height,
                                        "sizeBytes" to res.sizeBytes
                                    )
                                )
                            }
                        } catch (e: VideoTooLongException) {
                            mainHandler.post {
                                result.error("VIDEO_TOO_LONG", e.message, mapOf("durationMs" to e.durationMs))
                            }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error("GIF_ENCODE_FAILED", e.message ?: "Failed to convert video to GIF", null)
                            }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, voiceChannelName)
            .setMethodCallHandler { call, result ->
                val bridge = voiceBridge ?: AacVoiceBridge(applicationContext).also { voiceBridge = it }
                when (call.method) {
                    "processVoiceWav" -> {
                        val inPath = call.argument<String>("inputPath")
                        val outPath = call.argument<String>("outputPath")
                        val targetF0 = (call.argument<Double>("targetF0Hz") ?: 0.0).toFloat()
                        val formantSt = (call.argument<Double>("formantSemitones") ?: 0.0).toFloat()
                        if (inPath.isNullOrBlank() || outPath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "inputPath and outputPath are required", null)
                            return@setMethodCallHandler
                        }
                        voiceExecutor.execute {
                            try {
                                val ok = bridge.processVoiceWav(inPath, outPath, targetF0, formantSt)
                                mainHandler.post { result.success(ok) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("DSP_FAILED", e.message, null) }
                            }
                        }
                    }
                    "synthesizeFallbackWav" -> {
                        val text = call.argument<String>("text")
                        val localeTag = call.argument<String>("localeTag") ?: "en-US"
                        val outPath = call.argument<String>("outputPath")
                        val targetF0 = (call.argument<Double>("targetF0Hz") ?: 0.0).toFloat()
                        val formantSt = (call.argument<Double>("formantSemitones") ?: 0.0).toFloat()
                        val speechRate = (call.argument<Double>("speechRate") ?: 0.96).toFloat()
                        if (text.isNullOrBlank() || outPath.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "text and outputPath are required", null)
                            return@setMethodCallHandler
                        }
                        voiceExecutor.execute {
                            try {
                                val ok = bridge.synthesizeCleanFallbackWav(
                                    text,
                                    localeTag,
                                    outPath,
                                    targetF0,
                                    formantSt,
                                    speechRate
                                )
                                mainHandler.post { result.success(ok) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("TTS_FALLBACK_FAILED", e.message, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun analyzeImageOffline(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("Image file does not exist")
        }

        val (imgWidth, imgHeight, lumaMean, lumaStdDev) = measureLumaStats(path)
        val tooDark = lumaMean < 10.0 && lumaStdDev < 8.0
        val tooFlat = lumaStdDev < 6.0
        val isTooDarkOrBlank = tooDark || tooFlat

        val inputImage = InputImage.fromFilePath(applicationContext, Uri.fromFile(file))
        val effectiveW = max(1, if (imgWidth > 0) imgWidth else inputImage.width)
        val effectiveH = max(1, if (imgHeight > 0) imgHeight else inputImage.height)

        val labelTask = getLabeler().process(inputImage)
        val objectTask = getDetector().process(inputImage)
        Tasks.await(Tasks.whenAllComplete(labelTask, objectTask))

        val labels = if (labelTask.isSuccessful) labelTask.result else emptyList<ImageLabel>()
        val objects = if (objectTask.isSuccessful) objectTask.result else emptyList<DetectedObject>()

        val concreteLabels = mutableListOf<String>()
        var topConfidence = 0.0
        for (item in labels) {
            val text = item.text.trim()
            if (text.isEmpty()) continue
            val lower = text.lowercase()
            if (GENERIC_SURFACE_TAGS.contains(lower)) continue
            if (item.confidence > topConfidence) {
                topConfidence = item.confidence.toDouble()
            }
            if (!concreteLabels.any { it.equals(text, ignoreCase = true) }) {
                concreteLabels.add(text)
            }
        }

        var salientObjectCount = 0
        val objectCategoryLabels = mutableListOf<String>()
        val frameArea = effectiveW.toDouble() * effectiveH.toDouble()
        for (obj in objects) {
            if (!isReasonableForegroundBox(obj.boundingBox, frameArea)) continue
            salientObjectCount++
            for (cat in obj.labels) {
                val catText = cat.text.trim()
                if (catText.isEmpty() || GENERIC_SURFACE_TAGS.contains(catText.lowercase())) continue
                if (cat.confidence > topConfidence) {
                    topConfidence = cat.confidence.toDouble()
                }
                if (!objectCategoryLabels.any { it.equals(catText, ignoreCase = true) }) {
                    objectCategoryLabels.add(catText)
                }
            }
        }

        // Prefer specific 400-class ImageLabeler words; fall back to coarse ObjectDetector category if needed.
        val mergedSuggestions = mutableListOf<String>()
        for (label in concreteLabels) {
            if (mergedSuggestions.size >= 3) break
            mergedSuggestions.add(label)
        }
        if (mergedSuggestions.isEmpty()) {
            for (cat in objectCategoryLabels) {
                if (mergedSuggestions.size >= 2) break
                mergedSuggestions.add(cat)
            }
        }

        val hasObject = !isTooDarkOrBlank &&
            (concreteLabels.isNotEmpty() || (salientObjectCount > 0 && lumaStdDev >= 9.0))

        return mapOf(
            "hasObject" to hasObject,
            "isTooDarkOrBlank" to isTooDarkOrBlank,
            "labels" to if (hasObject) mergedSuggestions else emptyList<String>(),
            "topConfidence" to topConfidence,
            "objectCount" to salientObjectCount
        )
    }

    private fun isReasonableForegroundBox(box: Rect, frameArea: Double): Boolean {
        val boxArea = box.width().toDouble() * box.height().toDouble()
        if (boxArea <= 0.0 || frameArea <= 0.0) return false
        val ratio = boxArea / frameArea
        return ratio in 0.015..0.96
    }

    private data class LumaStats(
        val width: Int,
        val height: Int,
        val mean: Double,
        val stdDev: Double
    )

    private fun measureLumaStats(path: String): LumaStats {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        val rawW = bounds.outWidth
        val rawH = bounds.outHeight
        if (rawW <= 0 || rawH <= 0) {
            return LumaStats(0, 0, 0.0, 0.0)
        }

        var sample = 1
        while ((rawW / sample) > 96 || (rawH / sample) > 96) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.RGB_565
        }
        val bmp = BitmapFactory.decodeFile(path, opts) ?: return LumaStats(rawW, rawH, 0.0, 0.0)
        return try {
            val w = bmp.width
            val h = bmp.height
            val pixels = IntArray(w * h)
            bmp.getPixels(pixels, 0, w, 0, 0, w, h)
            var sum = 0.0
            var sumSq = 0.0
            for (px in pixels) {
                val r = (px shr 16) and 0xFF
                val g = (px shr 8) and 0xFF
                val b = px and 0xFF
                val luma = 0.299 * r + 0.587 * g + 0.114 * b
                sum += luma
                sumSq += luma * luma
            }
            val n = pixels.size.coerceAtLeast(1)
            val mean = sum / n
            val variance = max(0.0, (sumSq / n) - (mean * mean))
            LumaStats(rawW, rawH, mean, sqrt(variance))
        } finally {
            bmp.recycle()
        }
    }

    override fun onDestroy() {
        imageLabeler?.close()
        objectDetector?.close()
        imageLabeler = null
        objectDetector = null
        visionExecutor.shutdown()
        voiceBridge?.shutdown()
        voiceBridge = null
        voiceExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private val GENERIC_SURFACE_TAGS = setOf(
            "wall",
            "floor",
            "flooring",
            "ceiling",
            "plaster",
            "concrete",
            "asphalt",
            "wood",
            "hardwood",
            "laminate flooring",
            "tile",
            "pattern",
            "texture",
            "rectangle",
            "square",
            "circle",
            "triangle",
            "line",
            "white",
            "black",
            "gray",
            "grey",
            "beige",
            "brown",
            "darkness",
            "light",
            "shadow",
            "blur",
            "monochrome",
            "colorfulness",
            "material property",
            "surface",
            "space",
            "emptiness",
            "room",
            "interior design",
            "font"
        )
    }

    private fun saveToDownloads(fileName: String, bytes: ByteArray): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/zip")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("Failed to create MediaStore entry")
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw Exception("Failed to open output stream")
            uri.toString()
        } else {
            val downloadsDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val file = File(downloadsDir, fileName)
            FileOutputStream(file).use { stream ->
                stream.write(bytes)
            }
            file.absolutePath
        }
    }
}
