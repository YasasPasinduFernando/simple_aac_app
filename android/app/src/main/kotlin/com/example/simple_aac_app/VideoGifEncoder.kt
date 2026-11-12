package com.example.simple_aac_app

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.util.PriorityQueue
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

class VideoTooLongException(val durationMs: Long, val maxDurationMs: Long) :
    Exception("Video is ${(durationMs / 1000.0).roundToInt()}s long. Maximum allowed is ${maxDurationMs / 1000}s.")

/**
 * Offline MediaMetadataRetriever + adaptive 256-color Median-Cut GIF89a encoder.
 * Enforces max 30s duration and keeps fair quality in compact file sizes for AAC cards & backups.
 */
object VideoGifEncoder {
    private const val MAX_DURATION_MS = 30_500L
    private const val TARGET_MAX_DIM = 240
    private const val MAX_FRAMES = 90

    data class EncodeResult(
        val outputPath: String,
        val durationMs: Long,
        val frameCount: Int,
        val width: Int,
        val height: Int,
        val sizeBytes: Long
    )

    fun convertVideoToGif(
        context: Context,
        inputPath: String,
        outputPath: String
    ): EncodeResult {
        val inputFile = File(inputPath)
        if (!inputFile.exists() || inputFile.length() <= 0L) {
            throw IllegalArgumentException("Video file not found or empty")
        }

        val retriever = MediaMetadataRetriever()
        try {
            try {
                retriever.setDataSource(context, Uri.fromFile(inputFile))
            } catch (_: Exception) {
                retriever.setDataSource(inputPath)
            }

            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            if (durationMs <= 0L) {
                throw IllegalArgumentException("Unable to read video duration")
            }
            if (durationMs > MAX_DURATION_MS) {
                throw VideoTooLongException(durationMs, 30_000L)
            }

            val firstRaw = retriever.getFrameAtTime(0L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: retriever.getFrameAtTime(-1L)
                ?: throw IllegalStateException("Could not decode video frames")

            val srcW = firstRaw.width.coerceAtLeast(1)
            val srcH = firstRaw.height.coerceAtLeast(1)
            firstRaw.recycle()

            val scale = min(
                1.0,
                TARGET_MAX_DIM.toDouble() / max(srcW, srcH).toDouble()
            )
            // Even dimensions keep video/GIF decoders crisp.
            val outW = max(2, ((srcW * scale).roundToInt() / 2) * 2)
            val outH = max(2, ((srcH * scale).roundToInt() / 2) * 2)

            val desiredFps = when {
                durationMs <= 6_000L -> 8
                durationMs <= 15_000L -> 6
                else -> 4
            }
            val rawFrameCount = ((durationMs * desiredFps) / 1000.0).roundToInt()
            val frameCount = rawFrameCount.coerceIn(2, MAX_FRAMES)
            val frameDelayMs = (durationMs.toDouble() / frameCount).roundToInt().coerceIn(80, 500)
            val delayCs = (frameDelayMs / 10).coerceIn(8, 50)

            val outFile = File(outputPath)
            outFile.parentFile?.mkdirs()

            val argbBuffer = IntArray(outW * outH)
            val indexBuffer = ByteArray(outW * outH)
            var writtenFrames = 0

            BufferedOutputStream(FileOutputStream(outFile), 32 * 1024).use { out ->
                writeGifHeader(out, outW, outH)

                val stepUs = (durationMs * 1000L) / frameCount
                for (i in 0 until frameCount) {
                    val timeUs = (i * stepUs).coerceIn(0L, max(0L, (durationMs - 50L) * 1000L))
                    val bmp = extractScaledFrame(retriever, timeUs, outW, outH) ?: continue
                    try {
                        val prepared = if (bmp.width == outW && bmp.height == outH) {
                            bmp
                        } else {
                            Bitmap.createScaledBitmap(bmp, outW, outH, true)
                        }
                        try {
                            prepared.getPixels(argbBuffer, 0, outW, 0, 0, outW, outH)
                            val palette = quantizeMedianCut(argbBuffer, indexBuffer)
                            writeGraphicControlExt(out, delayCs)
                            writeImageDescriptor(out, outW, outH)
                            out.write(palette)
                            LzwGifWriter.encode(out, indexBuffer)
                            writtenFrames++
                        } finally {
                            if (prepared !== bmp) {
                                prepared.recycle()
                            }
                        }
                    } finally {
                        bmp.recycle()
                    }
                }

                if (writtenFrames == 0) {
                    throw IllegalStateException("No decodable frames extracted from video")
                }
                out.write(0x3B) // GIF Trailer
                out.flush()
            }

            return EncodeResult(
                outputPath = outFile.absolutePath,
                durationMs = durationMs,
                frameCount = writtenFrames,
                width = outW,
                height = outH,
                sizeBytes = outFile.length()
            )
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun extractScaledFrame(
        retriever: MediaMetadataRetriever,
        timeUs: Long,
        outW: Int,
        outH: Int
    ): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val scaled = retriever.getScaledFrameAtTime(
                timeUs,
                MediaMetadataRetriever.OPTION_CLOSEST,
                outW,
                outH
            )
            if (scaled != null) return scaled
        }
        return retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
            ?: retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
    }

    private fun writeGifHeader(out: OutputStream, w: Int, h: Int) {
        out.write("GIF89a".toByteArray(Charsets.US_ASCII))
        writeShortLE(out, w)
        writeShortLE(out, h)
        // Global Color Table Flag = 0, Color Resolution = 7 (111), Sort = 0, Size = 0 -> 0x70
        out.write(0x70)
        out.write(0x00) // Background color index
        out.write(0x00) // Pixel aspect ratio

        // Netscape 2.0 Application Extension for infinite looping
        out.write(0x21)
        out.write(0xFF)
        out.write(0x0B)
        out.write("NETSCAPE2.0".toByteArray(Charsets.US_ASCII))
        out.write(0x03)
        out.write(0x01)
        out.write(0x00)
        out.write(0x00)
        out.write(0x00)
    }

    private fun writeGraphicControlExt(out: OutputStream, delayCs: Int) {
        out.write(0x21)
        out.write(0xF9)
        out.write(0x04)
        out.write(0x04) // Disposal method 1 (leave in place)
        writeShortLE(out, delayCs)
        out.write(0x00)
        out.write(0x00)
    }

    private fun writeImageDescriptor(out: OutputStream, w: Int, h: Int) {
        out.write(0x2C)
        writeShortLE(out, 0)
        writeShortLE(out, 0)
        writeShortLE(out, w)
        writeShortLE(out, h)
        // Local Color Table = 1, Interlace = 0, Sort = 0, Size = 7 (2^(7+1) = 256)
        out.write(0x87)
    }

    private fun writeShortLE(out: OutputStream, value: Int) {
        out.write(value and 0xFF)
        out.write((value shr 8) and 0xFF)
    }

    private class ColorBox(
        val keys: IntArray,
        val counts: IntArray,
        val start: Int,
        val end: Int
    ) {
        var minR = 31; var maxR = 0
        var minG = 31; var maxG = 0
        var minB = 31; var maxB = 0
        var totalPixels = 0

        init {
            for (i in start until end) {
                val k = keys[i]
                val r = (k shr 10) and 31
                val g = (k shr 5) and 31
                val b = k and 31
                if (r < minR) minR = r
                if (r > maxR) maxR = r
                if (g < minG) minG = g
                if (g > maxG) maxG = g
                if (b < minB) minB = b
                if (b > maxB) maxB = b
                totalPixels += counts[k]
            }
        }

        val volumeScore: Int
            get() {
                val span = max(maxR - minR, max(maxG - minG, maxB - minB))
                return if (end - start <= 1) 0 else span * totalPixels
            }
    }

    private fun quantizeMedianCut(pixels: IntArray, outIndices: ByteArray): ByteArray {
        val counts = IntArray(32768)
        var uniqueCount = 0
        for (px in pixels) {
            val r5 = (px shr 19) and 31
            val g5 = (px shr 11) and 31
            val b5 = (px shr 3) and 31
            val key = (r5 shl 10) or (g5 shl 5) or b5
            if (counts[key] == 0) uniqueCount++
            counts[key]++
        }

        val keys = IntArray(uniqueCount)
        var idx = 0
        for (k in 0 until 32768) {
            if (counts[k] > 0) keys[idx++] = k
        }

        val pq = PriorityQueue<ColorBox>(256, Comparator { a, b ->
            b.volumeScore.compareTo(a.volumeScore)
        })
        if (uniqueCount > 0) {
            pq.add(ColorBox(keys, counts, 0, uniqueCount))
        }

        while (pq.size < 256 && pq.isNotEmpty()) {
            val box = pq.peek()
            if (box == null || (box.end - box.start) <= 1) break
            pq.poll()

            val spanR = box.maxR - box.minR
            val spanG = box.maxG - box.minG
            val spanB = box.maxB - box.minB
            val axis = when {
                spanR >= spanG && spanR >= spanB -> 0
                spanG >= spanB -> 1
                else -> 2
            }

            // Sort slice by chosen channel
            val slice = IntArray(box.end - box.start) { keys[box.start + it] }
            val boxed = slice.sortedBy { k ->
                when (axis) {
                    0 -> (k shr 10) and 31
                    1 -> (k shr 5) and 31
                    else -> k and 31
                }
            }
            for (i in boxed.indices) {
                keys[box.start + i] = boxed[i]
            }

            var running = 0
            val half = box.totalPixels / 2
            var mid = box.start + 1
            for (i in box.start until (box.end - 1)) {
                running += counts[keys[i]]
                mid = i + 1
                if (running >= half) break
            }

            pq.add(ColorBox(keys, counts, box.start, mid))
            pq.add(ColorBox(keys, counts, mid, box.end))
        }

        val palette = ByteArray(256 * 3)
        val lut = ByteArray(32768)
        var palIdx = 0
        for (box in pq) {
            if (palIdx >= 256) break
            var sumR = 0L
            var sumG = 0L
            var sumB = 0L
            var totalW = 0L
            for (i in box.start until box.end) {
                val k = keys[i]
                val w = counts[k].toLong()
                val r5 = (k shr 10) and 31
                val g5 = (k shr 5) and 31
                val b5 = k and 31
                sumR += ((r5 shl 3) or (r5 shr 2)) * w
                sumG += ((g5 shl 3) or (g5 shr 2)) * w
                sumB += ((b5 shl 3) or (b5 shr 2)) * w
                totalW += w
                lut[k] = palIdx.toByte()
            }
            if (totalW > 0) {
                palette[palIdx * 3] = (sumR / totalW).toInt().coerceIn(0, 255).toByte()
                palette[palIdx * 3 + 1] = (sumG / totalW).toInt().coerceIn(0, 255).toByte()
                palette[palIdx * 3 + 2] = (sumB / totalW).toInt().coerceIn(0, 255).toByte()
            }
            palIdx++
        }

        for (i in pixels.indices) {
            val px = pixels[i]
            val key = (((px shr 19) and 31) shl 10) or
                (((px shr 11) and 31) shl 5) or
                ((px shr 3) and 31)
            outIndices[i] = lut[key]
        }

        return palette
    }

    private object LzwGifWriter {
        private const val HSIZE = 5003
        private const val CLEAR_CODE = 256
        private const val EOF_CODE = 257

        fun encode(out: OutputStream, pixels: ByteArray) {
            out.write(8) // LZW minimum code size

            val htab = IntArray(HSIZE) { -1 }
            val codetab = IntArray(HSIZE)
            val block = ByteArray(256)
            var blockPos = 0

            var nBits = 9
            var maxCode = (1 shl nBits) - 1
            var freeEnt = EOF_CODE + 1
            var curAccum = 0
            var curBits = 0

            fun flushBlock() {
                if (blockPos > 0) {
                    out.write(blockPos)
                    out.write(block, 0, blockPos)
                    blockPos = 0
                }
            }

            fun charOut(b: Int) {
                block[blockPos++] = b.toByte()
                if (blockPos >= 254) {
                    flushBlock()
                }
            }

            fun outputCode(code: Int) {
                curAccum = curAccum or (code shl curBits)
                curBits += nBits
                while (curBits >= 8) {
                    charOut(curAccum and 0xFF)
                    curAccum = curAccum ushr 8
                    curBits -= 8
                }
                if (freeEnt > maxCode) {
                    if (nBits < 12) {
                        nBits++
                        maxCode = (1 shl nBits) - 1
                    }
                }
            }

            fun resetTable() {
                htab.fill(-1)
                freeEnt = EOF_CODE + 1
                nBits = 9
                maxCode = (1 shl nBits) - 1
            }

            outputCode(CLEAR_CODE)
            if (pixels.isNotEmpty()) {
                var ent = pixels[0].toInt() and 0xFF
                for (p in 1 until pixels.size) {
                    val c = pixels[p].toInt() and 0xFF
                    val fcode = (c shl 12) + ent
                    var i = ((c shl 4) xor ent) % HSIZE
                    if (i < 0) i += HSIZE

                    var hit = false
                    if (htab[i] == fcode) {
                        ent = codetab[i]
                        continue
                    } else if (htab[i] >= 0) {
                        var disp = HSIZE - i
                        if (i == 0) disp = 1
                        while (true) {
                            i -= disp
                            if (i < 0) i += HSIZE
                            if (htab[i] == fcode) {
                                ent = codetab[i]
                                hit = true
                                break
                            }
                            if (htab[i] < 0) break
                        }
                        if (hit) continue
                    }

                    outputCode(ent)
                    ent = c
                    if (freeEnt < 4096) {
                        codetab[i] = freeEnt++
                        htab[i] = fcode
                    } else {
                        outputCode(CLEAR_CODE)
                        resetTable()
                    }
                }
                outputCode(ent)
            }

            outputCode(EOF_CODE)
            while (curBits > 0) {
                charOut(curAccum and 0xFF)
                curAccum = curAccum ushr 8
                curBits -= 8
            }
            flushBlock()
            out.write(0x00) // Block Terminator
        }
    }
}
