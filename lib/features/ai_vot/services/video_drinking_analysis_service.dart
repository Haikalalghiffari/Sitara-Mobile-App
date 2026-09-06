import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import '../models/drinking_analysis_result.dart';
import '../utils/video_frame_extractor.dart';

/// Service untuk menganalisis video proses minum obat secara lokal (post-recording).
///
/// Tanggung jawab:
/// 1. Memanggil [VideoFrameExtractor] untuk ekstraksi sample frame & native hand landmarks.
/// 2. Menjalankan MediaPipe FaceMesh untuk mencari titik mulut per frame.
/// 3. Menghitung jarak Euclidean normalized (0.0 - 1.0) tangan-ke-mulut.
/// 4. Menganalisis sekuens temporal gerakan (Far -> Approach -> Near -> Withdraw).
/// 5. Menghitung AI Confidence Score berdasarkan evidence riil.
class VideoDrinkingAnalysisService {
  VideoDrinkingAnalysisService({
    VideoFrameExtractor? frameExtractor,
  }) : _frameExtractor = frameExtractor ?? const VideoFrameExtractor();

  final VideoFrameExtractor _frameExtractor;

  static const double nearThreshold = 0.22;
  static const double farThreshold = 0.34;
  static const double approachDelta = 0.02;

  /// Ambang batas minimum skor keyakinan untuk lolos verifikasi otomatis.
  static const double autoVerifyThreshold = 80.0;

  /// Ambang batas medium review.
  static const double mediumReviewThreshold = 50.0;

  /// Landmark FaceMesh bibir atas & bawah.
  static const int _upperLipIndex = 13;
  static const int _lowerLipIndex = 14;

  /// Menganalisis video rekaman MP4 [videoPath].
  Future<DrinkingAnalysisResult> analyzeVideo({
    required String videoPath,
    int sampleCount = 18,
  }) async {
    final File videoFile = File(videoPath);
    if (!videoFile.existsSync()) {
      return const DrinkingAnalysisResult(
        videoDurationMs: 0,
        framesExtracted: 0,
        faceDetectedFrames: 0,
        handDetectedFrames: 0,
        validDistanceFrames: 0,
        minDistance: null,
        maxDistance: null,
        nearMouthDetected: false,
        approachDetected: false,
        withdrawDetected: false,
        sequenceCompleted: false,
        confidenceScore: 0.0,
        level: DrinkingConfidenceLevel.low,
        isAutoVerified: false,
        reason: 'File video tidak ditemukan di penyimpanan lokal.',
      );
    }

    // 1. Ekstrak frame video via native Android MediaMetadataRetriever + MediaPipe HandLandmarker
    final List<ExtractedVideoFrame> frames = await _frameExtractor.extractFrames(
      videoPath: videoPath,
      sampleCount: sampleCount,
    );

    if (frames.isEmpty) {
      return const DrinkingAnalysisResult(
        videoDurationMs: 0,
        framesExtracted: 0,
        faceDetectedFrames: 0,
        handDetectedFrames: 0,
        validDistanceFrames: 0,
        minDistance: null,
        maxDistance: null,
        nearMouthDetected: false,
        approachDetected: false,
        withdrawDetected: false,
        sequenceCompleted: false,
        confidenceScore: 0.0,
        level: DrinkingConfidenceLevel.low,
        isAutoVerified: false,
        reason: 'Ekstraksi frame video menghasilkan 0 frame.',
      );
    }

    final int totalFrames = frames.length;
    final int videoDurationMs = frames.last.timestampMs;

    // 2. Inisialisasi pipeline MediaPipe FaceMesh
    FaceDetectorProcessor? detector;
    FaceMeshProcessor? mesh;
    FaceMeshInferencePipeline? pipeline;

    try {
      detector = await FaceDetectorProcessor.create();
      mesh = await FaceMeshProcessor.create(model: FaceMeshModel.v2);
      pipeline = FaceMeshInferencePipeline(
        detector: detector,
        mesh: mesh,
      );
    } catch (e) {
      debugPrint('[VideoDrinkingAnalysisService] Gagal inisialisasi FaceMesh: $e');
      await _frameExtractor.clearFrames(frames);
      return DrinkingAnalysisResult(
        videoDurationMs: videoDurationMs,
        framesExtracted: totalFrames,
        faceDetectedFrames: 0,
        handDetectedFrames: 0,
        validDistanceFrames: 0,
        minDistance: null,
        maxDistance: null,
        nearMouthDetected: false,
        approachDetected: false,
        withdrawDetected: false,
        sequenceCompleted: false,
        confidenceScore: 0.0,
        level: DrinkingConfidenceLevel.low,
        isAutoVerified: false,
        reason: 'Gagal inisialisasi model FaceMesh di perangkat.',
      );
    }

    // 3. Evaluasi setiap frame
    final List<FrameAnalysis> frameAnalyses = <FrameAnalysis>[];
    int faceDetectedCount = 0;
    int handDetectedCount = 0;
    int validDistanceCount = 0;
    double? minOverallDistance;
    double? maxOverallDistance;

    for (int i = 0; i < frames.length; i++) {
      final ExtractedVideoFrame frame = frames[i];
      final File file = frame.file;

      bool faceInFrame = false;
      ui.Offset? mouth;

      if (file.existsSync()) {
        try {
          final Uint8List bytes = await file.readAsBytes();
          final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
          final ui.Codec codec = await descriptor.instantiateCodec();
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image uiImage = frameInfo.image;
          final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);

          if (byteData != null) {
            final FaceMeshImage faceImage = FaceMeshImage(
              pixels: byteData.buffer.asUint8List(),
              width: uiImage.width,
              height: uiImage.height,
              bytesPerRow: uiImage.width * 4,
              pixelFormat: 0, // RGBA
            );

            // Single source of truth: tanpa rotasi dan tanpa mirror horizontal
            final FaceMeshInferenceResult inference = pipeline.process(
              faceImage,
              rotationDegrees: 0,
              mirrorHorizontal: false,
            );

            final FaceMeshResult? meshResult = inference.meshResult;
            if (meshResult != null && meshResult.landmarks.length > _lowerLipIndex) {
              faceInFrame = true;
              final FaceMeshLandmark upper = meshResult.landmarks[_upperLipIndex];
              final FaceMeshLandmark lower = meshResult.landmarks[_lowerLipIndex];
              // Normalized coordinates 0.0 - 1.0 langsung dari MediaPipe FaceMesh
              mouth = ui.Offset((upper.x + lower.x) / 2.0, (upper.y + lower.y) / 2.0);
            }
          }

          buffer.dispose();
          descriptor.dispose();
          uiImage.dispose();
        } catch (e) {
          debugPrint('[VideoDrinkingAnalysisService] Error frame #$i: $e');
        }
      }

      if (faceInFrame) faceDetectedCount++;
      if (frame.handDetected) handDetectedCount++;

      debugPrint(
        '[VOT][MOUTH][FRAME] index=$i timestamp=${frame.timestampMs}ms detected=$faceInFrame mouth=(${mouth?.dx.toStringAsFixed(3)}, ${mouth?.dy.toStringAsFixed(3)})',
      );

      double? dist;
      if (mouth != null && frame.handDetected) {
        dist = frame.minDistanceToMouth(mouth);
        if (dist != null) {
          validDistanceCount++;
          minOverallDistance = minOverallDistance == null
              ? dist
              : math.min(minOverallDistance, dist);
          maxOverallDistance = maxOverallDistance == null
              ? dist
              : math.max(maxOverallDistance, dist);

          final double handX = frame.indexTipX ?? frame.middleTipX ?? frame.thumbTipX ?? 0.0;
          final double handY = frame.indexTipY ?? frame.middleTipY ?? frame.thumbTipY ?? 0.0;
          debugPrint(
            '[VOT][COORD] hand=(${handX.toStringAsFixed(3)}, ${handY.toStringAsFixed(3)}) mouth=(${mouth.dx.toStringAsFixed(3)}, ${mouth.dy.toStringAsFixed(3)}) distance=${dist.toStringAsFixed(3)}',
          );
        }
      }

      frameAnalyses.add(
        FrameAnalysis(
          index: i,
          timestampMs: frame.timestampMs,
          path: frame.path,
          width: frame.width,
          height: frame.height,
          faceDetected: faceInFrame,
          handDetected: frame.handDetected,
          mouthX: mouth?.dx,
          mouthY: mouth?.dy,
          thumbTipX: frame.thumbTipX,
          thumbTipY: frame.thumbTipY,
          indexTipX: frame.indexTipX,
          indexTipY: frame.indexTipY,
          middleTipX: frame.middleTipX,
          middleTipY: frame.middleTipY,
          handMouthDistance: dist,
        ),
      );
    }

    // 4. Bersihkan resource FaceMesh & file frame temporary
    pipeline = null;
    mesh.close();
    detector.close();
    await _frameExtractor.clearFrames(frames);

    // 5. Analisis Sekuens Temporal (Far -> Approach -> Near -> Withdraw)
    final _TemporalAnalysis temporal = _evaluateTemporalSequence(frameAnalyses);

    // 6. Kalkulasi AI Confidence Score (0 - 100) berdasarkan evidence nyata
    final double handScore = (handDetectedCount / totalFrames) * 30.0;
    final double mouthScore = (faceDetectedCount / totalFrames) * 25.0;
    final double nearScore = temporal.nearMouthDetected ? 25.0 : 0.0;
    final double sequenceScore = temporal.sequenceCompleted
        ? 20.0
        : ((temporal.approachDetected || temporal.withdrawDetected) ? 10.0 : 0.0);

    final double totalConfidence = (handScore + mouthScore + nearScore + sequenceScore)
        .clamp(0.0, 100.0);

    // 7. Penentuan Kategori Hasil
    final DrinkingConfidenceLevel level;
    final bool isAutoVerified;
    final String reason;

    if (totalConfidence >= autoVerifyThreshold &&
        temporal.nearMouthDetected &&
        temporal.sequenceCompleted) {
      level = DrinkingConfidenceLevel.high;
      isAutoVerified = true;
      reason = 'Visual drinking sequence detected with high confidence (${totalConfidence.toStringAsFixed(1)}%).';
    } else if (totalConfidence >= mediumReviewThreshold && temporal.nearMouthDetected) {
      level = DrinkingConfidenceLevel.medium;
      isAutoVerified = false;
      reason = 'Visual drinking sequence partially detected (${totalConfidence.toStringAsFixed(1)}%). Needs Nakes review.';
    } else {
      level = DrinkingConfidenceLevel.low;
      isAutoVerified = false;
      reason = 'Visual drinking sequence could not be confidently detected (${totalConfidence.toStringAsFixed(1)}%).';
    }

    final DrinkingAnalysisResult result = DrinkingAnalysisResult(
      videoDurationMs: videoDurationMs,
      framesExtracted: totalFrames,
      faceDetectedFrames: faceDetectedCount,
      handDetectedFrames: handDetectedCount,
      validDistanceFrames: validDistanceCount,
      minDistance: minOverallDistance,
      maxDistance: maxOverallDistance,
      nearMouthDetected: temporal.nearMouthDetected,
      approachDetected: temporal.approachDetected,
      withdrawDetected: temporal.withdrawDetected,
      sequenceCompleted: temporal.sequenceCompleted,
      confidenceScore: totalConfidence,
      level: level,
      isAutoVerified: isAutoVerified,
      reason: reason,
      frameAnalyses: frameAnalyses,
    );

    // Cetak log terstruktur sesuai spesifikasi STEP 7
    final int nearMouthFramesCount = frameAnalyses
        .where((FrameAnalysis f) => f.handMouthDistance != null && f.handMouthDistance! <= nearThreshold)
        .length;

    debugPrint('''
[VOT][AI ANALYSIS RESULT]
framesExtracted=$totalFrames
handDetectedFrames=$handDetectedCount
mouthDetectedFrames=$faceDetectedCount
nearMouthFrames=$nearMouthFramesCount

sequence:
FAR=${temporal.firstFarDetected ? 'YES' : 'NO'}
APPROACH=${temporal.approachDetected ? 'YES' : 'NO'}
NEAR=${temporal.nearMouthDetected ? 'YES' : 'NO'}
WITHDRAW=${temporal.withdrawDetected ? 'YES' : 'NO'}

confidence=${totalConfidence.toStringAsFixed(1)}%
level=${result.statusLabel}
autoVerified=$isAutoVerified
''');

    // Cetak ringkasan banner
    result.printDiagnosticSummary();

    return result;
  }

  /// Evaluasi urutan temporal: FAR -> APPROACHING -> NEAR_MOUTH -> WITHDRAWING
  _TemporalAnalysis _evaluateTemporalSequence(List<FrameAnalysis> frames) {
    int? firstFarIndex;
    int? approachIndex;
    int? nearIndex;
    int? withdrawIndex;

    // Filter frame yang memiliki jarak valid
    final List<MapEntry<int, double>> validDistances = <MapEntry<int, double>>[];
    for (final FrameAnalysis f in frames) {
      if (f.handMouthDistance != null) {
        validDistances.add(MapEntry<int, double>(f.index, f.handMouthDistance!));
      }
    }

    if (validDistances.isEmpty) {
      return const _TemporalAnalysis(
        firstFarDetected: false,
        nearMouthDetected: false,
        approachDetected: false,
        withdrawDetected: false,
        sequenceCompleted: false,
      );
    }

    // Cari titik awal FAR (jarak >= farThreshold)
    for (final MapEntry<int, double> entry in validDistances) {
      if (entry.value >= farThreshold) {
        firstFarIndex = entry.key;
        break;
      }
    }

    // Cari titik NEAR MOUTH (jarak <= nearThreshold)
    for (final MapEntry<int, double> entry in validDistances) {
      if (entry.value <= nearThreshold) {
        nearIndex = entry.key;
        break;
      }
    }

    // Cek APPROACHING: apakah sebelum nearIndex ada penurunan jarak menuju mulut?
    if (nearIndex != null) {
      for (final MapEntry<int, double> entry in validDistances) {
        if (entry.key < nearIndex && entry.value > nearThreshold) {
          approachIndex = entry.key;
          break;
        }
      }
    }

    // Cek WITHDRAWING: apakah setelah nearIndex ada frame di mana tangan menjauh kembali?
    if (nearIndex != null) {
      for (final MapEntry<int, double> entry in validDistances) {
        if (entry.key > nearIndex && entry.value >= nearThreshold + approachDelta) {
          withdrawIndex = entry.key;
          break;
        }
      }
    }

    final bool firstFar = firstFarIndex != null;
    final bool nearDetected = nearIndex != null;
    final bool approachDetected = approachIndex != null || firstFar;
    final bool withdrawDetected = withdrawIndex != null;

    // Sequence valid jika urutannya kronologis: (Far/Approach) -> Near -> Withdraw
    final bool sequenceValid = nearDetected &&
        withdrawDetected &&
        (approachIndex == null || nearIndex > approachIndex) &&
        (withdrawIndex > nearIndex);

    return _TemporalAnalysis(
      firstFarDetected: firstFar,
      nearMouthDetected: nearDetected,
      approachDetected: approachDetected,
      withdrawDetected: withdrawDetected,
      sequenceCompleted: sequenceValid,
    );
  }
}

class _TemporalAnalysis {
  const _TemporalAnalysis({
    required this.firstFarDetected,
    required this.nearMouthDetected,
    required this.approachDetected,
    required this.withdrawDetected,
    required this.sequenceCompleted,
  });

  final bool firstFarDetected;
  final bool nearMouthDetected;
  final bool approachDetected;
  final bool withdrawDetected;
  final bool sequenceCompleted;
}

