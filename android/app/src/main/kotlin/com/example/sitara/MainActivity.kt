package com.example.sitara

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.util.Log
import android.view.WindowManager
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val screenAwakeChannel = "sitara/screen_awake"
    private val videoAnalysisChannel = "sitara/video_analysis"
    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private var handLandmarker: HandLandmarker? = null

    companion object {
        private const val TAG = "VOT FRAME"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Screen Awake Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenAwakeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        runOnUiThread {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    "disable" -> {
                        runOnUiThread {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Video Analysis Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, videoAnalysisChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractFrames" -> handleExtractFrames(call, result)
                    "clearFrames" -> handleClearFrames(result)
                    else -> result.notImplemented()
                }
            }
    }

    @Synchronized
    private fun getOrCreateHandLandmarker(): HandLandmarker {
        if (handLandmarker == null) {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(RunningMode.IMAGE)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.4f)
                .setMinHandPresenceConfidence(0.4f)
                .setMinTrackingConfidence(0.4f)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(applicationContext, options)
        }
        return handLandmarker!!
    }

    private fun handleExtractFrames(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val sampleCount = call.argument<Int>("sampleCount") ?: 15

        if (videoPath.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "videoPath cannot be null or empty", null)
            return
        }

        val videoFile = File(videoPath)
        if (!videoFile.exists() || !videoFile.isFile) {
            result.error("VIDEO_NOT_FOUND", "Video file not found at: $videoPath", null)
            return
        }

        backgroundExecutor.execute {
            val retriever = MediaMetadataRetriever()
            val landmarker: HandLandmarker
            try {
                landmarker = getOrCreateHandLandmarker()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize HandLandmarker: ${e.message}", e)
                runOnUiThread {
                    result.error("HAND_LANDMARKER_INIT_FAILED", "Failed to initialize HandLandmarker: ${e.message}", null)
                }
                return@execute
            }

            try {
                retriever.setDataSource(videoFile.absolutePath)
                val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                val durationMs = durationStr?.toLongOrNull() ?: 0L

                if (durationMs <= 0L) {
                    runOnUiThread {
                        result.error("VIDEO_OPEN_FAILED", "Invalid video duration: $durationMs ms", null)
                    }
                    return@execute
                }

                val count = if (sampleCount <= 0) 15 else sampleCount
                Log.d(TAG, "videoPath=$videoPath")
                Log.d(TAG, "durationMs=$durationMs")
                Log.d(TAG, "sampleCount=$count")

                val framesDir = File(cacheDir, "vot_frames")
                if (!framesDir.exists()) {
                    framesDir.mkdirs()
                }

                val frameList = ArrayList<Map<String, Any?>>()
                val intervalUs = if (count > 1) {
                    (durationMs * 1000L) / (count - 1)
                } else {
                    (durationMs * 1000L) / 2
                }

                var framesExtractedCount = 0
                var framesSavedCount = 0
                var handDetectedTotalCount = 0

                for (i in 0 until count) {
                    val timeUs = if (count == 1) intervalUs else Math.min(i * intervalUs, durationMs * 1000L)
                    val timestampMs = timeUs / 1000L

                    val sourceBitmap: Bitmap? = try {
                        retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                            ?: retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed retrieving frame at $timestampMs ms: ${e.message}")
                        null
                    }

                    if (sourceBitmap != null) {
                        framesExtractedCount++
                        val sourceConfig = sourceBitmap.config
                        val width = sourceBitmap.width
                        val height = sourceBitmap.height

                        // FIX 1 — FORCE ARGB_8888: Buat copy terpisah untuk MediaPipe HandLandmarker
                        var analysisBitmap: Bitmap? = null
                        try {
                            analysisBitmap = sourceBitmap.copy(Bitmap.Config.ARGB_8888, true)
                        } catch (e: Exception) {
                            Log.w(TAG, "[VOT][FRAME] Failed copying to ARGB_8888: ${e.message}")
                        }

                        val analysisConfig = analysisBitmap?.config

                        Log.d(TAG, "[VOT][FRAME] index=$i")
                        Log.d(TAG, "[VOT][FRAME] timestamp=$timestampMs")
                        Log.d(TAG, "[VOT][FRAME] sourceConfig=$sourceConfig")
                        Log.d(TAG, "[VOT][FRAME] analysisConfig=$analysisConfig")
                        Log.d(TAG, "[VOT][FRAME] width=$width")
                        Log.d(TAG, "[VOT][FRAME] height=$height")

                        var handDetected = false
                        var thumbTipX: Double? = null
                        var thumbTipY: Double? = null
                        var indexTipX: Double? = null
                        var indexTipY: Double? = null
                        var middleTipX: Double? = null
                        var middleTipY: Double? = null

                        // FIX 2 & 4 — SEPARATE OWNERSHIP & ERROR ISOLATION:
                        // Deteksi hand landmark pada analysisBitmap; kegagalan tidak membatalkan frame JPEG
                        if (analysisBitmap != null && analysisConfig == Bitmap.Config.ARGB_8888) {
                            var mpImage: MPImage? = null
                            try {
                                mpImage = BitmapImageBuilder(analysisBitmap).build()
                                val detectionResult: HandLandmarkerResult = landmarker.detect(mpImage)
                                val landmarksList = detectionResult.landmarks()
                                if (!landmarksList.isNullOrEmpty()) {
                                    val firstHand = landmarksList[0]
                                    if (firstHand.size > 12) {
                                        handDetected = true
                                        val thumb = firstHand[4]
                                        val index = firstHand[8]
                                        val middle = firstHand[12]

                                        thumbTipX = thumb.x().toDouble()
                                        thumbTipY = thumb.y().toDouble()
                                        indexTipX = index.x().toDouble()
                                        indexTipY = index.y().toDouble()
                                        middleTipX = middle.x().toDouble()
                                        middleTipY = middle.y().toDouble()

                                        Log.d(
                                            TAG,
                                            "[VOT][HAND][FRAME] timestamp=$timestampMs detected=true thumb=(${String.format("%.2f", thumbTipX)}, ${String.format("%.2f", thumbTipY)}) index=(${String.format("%.2f", indexTipX)}, ${String.format("%.2f", indexTipY)}) middle=(${String.format("%.2f", middleTipX)}, ${String.format("%.2f", middleTipY)})"
                                        )
                                    }
                                }
                            } catch (e: Exception) {
                                Log.w(TAG, "[VOT][HAND][ERROR] timestamp=$timestampMs error=${e.message}")
                            } finally {
                                try {
                                    mpImage?.close()
                                } catch (_: Exception) {}
                            }
                        } else {
                            Log.w(TAG, "[VOT][HAND][ERROR] timestamp=$timestampMs analysisBitmap is null or not ARGB_8888")
                        }

                        if (handDetected) {
                            handDetectedTotalCount++
                        }
                        Log.d(TAG, "[VOT][HAND] detected=$handDetected")

                        // FIX 2 & 3 — SEPARATE BITMAP OWNERSHIP & SAFE COMPRESSION:
                        // sourceBitmap adalah instance terpisah yang tidak terpengaruh mpImage.close()
                        val saveBitmapRecycledBeforeCompress = sourceBitmap.isRecycled
                        Log.d(TAG, "[VOT][FRAME] saveBitmapRecycledBeforeCompress=$saveBitmapRecycledBeforeCompress")

                        var jpegSaved = false
                        if (!saveBitmapRecycledBeforeCompress) {
                            val frameFile = File(framesDir, "frame_${System.currentTimeMillis()}_${i}_${timestampMs}ms.jpg")
                            var fos: FileOutputStream? = null
                            try {
                                fos = FileOutputStream(frameFile)
                                sourceBitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                                fos.flush()
                                jpegSaved = true
                                framesSavedCount++

                                val frameMap = HashMap<String, Any?>()
                                frameMap["path"] = frameFile.absolutePath
                                frameMap["timestampMs"] = timestampMs
                                frameMap["width"] = width
                                frameMap["height"] = height
                                frameMap["handDetected"] = handDetected
                                frameMap["thumbTipX"] = thumbTipX
                                frameMap["thumbTipY"] = thumbTipY
                                frameMap["indexTipX"] = indexTipX
                                frameMap["indexTipY"] = indexTipY
                                frameMap["middleTipX"] = middleTipX
                                frameMap["middleTipY"] = middleTipY

                                frameList.add(frameMap)
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed writing frame $i: ${e.message}")
                            } finally {
                                try {
                                    fos?.close()
                                } catch (_: Exception) {}
                            }
                        }

                        Log.d(TAG, "[VOT][FRAME] jpegSaved=$jpegSaved")

                        // FIX 3 — RESOURCE CLEANUP: Cleanup masing-masing Bitmap secara aman
                        try {
                            if (analysisBitmap != null && !analysisBitmap.isRecycled) {
                                analysisBitmap.recycle()
                            }
                        } catch (_: Exception) {}

                        try {
                            if (!sourceBitmap.isRecycled) {
                                sourceBitmap.recycle()
                            }
                        } catch (_: Exception) {}
                    }
                }

                Log.d(TAG, """
[VOT][FRAME EXTRACTION RESULT]
requested=$count
extracted=$framesExtractedCount
saved=$framesSavedCount
handDetected=$handDetectedTotalCount
""".trimIndent())

                if (frameList.isEmpty()) {
                    runOnUiThread {
                        result.error("FRAME_EXTRACTION_FAILED", "Failed to extract any frames from video", null)
                    }
                    return@execute
                }

                Log.d(TAG, "Extracted ${frameList.size} frames successfully (HandLandmarker active)")
                runOnUiThread {
                    result.success(frameList)
                }
            } catch (e: Exception) {
                Log.e(TAG, "extractFrames failed: ${e.message}", e)
                runOnUiThread {
                    result.error("FRAME_EXTRACTION_FAILED", "Exception extracting frames: ${e.message}", null)
                }
            } finally {
                try {
                    retriever.release()
                } catch (_: Exception) {}
            }
        }
    }

    private fun handleClearFrames(result: MethodChannel.Result) {
        backgroundExecutor.execute {
            try {
                val framesDir = File(cacheDir, "vot_frames")
                var count = 0
                if (framesDir.exists() && framesDir.isDirectory) {
                    framesDir.listFiles()?.forEach { file ->
                        if (file.isFile && file.name.endsWith(".jpg", ignoreCase = true)) {
                            if (file.delete()) {
                                count++
                            }
                        }
                    }
                }
                Log.d(TAG, "clearFrames: deleted $count temporary frame files")
                runOnUiThread {
                    result.success(true)
                }
            } catch (e: Exception) {
                Log.e(TAG, "clearFrames error: ${e.message}", e)
                runOnUiThread {
                    result.success(false)
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            handLandmarker?.close()
            handLandmarker = null
        } catch (_: Exception) {}
        backgroundExecutor.shutdown()
    }
}


