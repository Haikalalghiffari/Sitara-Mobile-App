import 'package:flutter/foundation.dart';

/// Kategori tingkat keyakinan analisis AI terhadap proses minum obat visual.
enum DrinkingConfidenceLevel {
  /// Skor >= 80%: Evidence lengkap dan sekuens temporal valid -> Verifikasi Otomatis.
  high,

  /// Skor 50% - 79%: Evidence sebagian terdeteksi -> Memerlukan pemeriksaan tenaga kesehatan.
  medium,

  /// Skor < 50%: Evidence tidak mencukupi / sekuens tidak lengkap -> Wajib review manual Nakes.
  low,
}

/// Data detail evaluasi frame tunggal untuk inspeksi dan diagnostic.
class FrameAnalysis {
  const FrameAnalysis({
    required this.index,
    required this.timestampMs,
    required this.path,
    required this.width,
    required this.height,
    required this.faceDetected,
    required this.handDetected,
    this.mouthX,
    this.mouthY,
    this.thumbTipX,
    this.thumbTipY,
    this.indexTipX,
    this.indexTipY,
    this.middleTipX,
    this.middleTipY,
    this.handMouthDistance,
  });

  final int index;
  final int timestampMs;
  final String path;
  final int width;
  final int height;
  final bool faceDetected;
  final bool handDetected;
  final double? mouthX;
  final double? mouthY;
  final double? thumbTipX;
  final double? thumbTipY;
  final double? indexTipX;
  final double? indexTipY;
  final double? middleTipX;
  final double? middleTipY;
  final double? handMouthDistance;

  @override
  String toString() =>
      'Frame #$index @${timestampMs}ms: face=$faceDetected, hand=$handDetected, dist=${handMouthDistance?.toStringAsFixed(3) ?? "null"}';
}

/// Model hasil akhir analisis video proses minum obat (Post-Recording Video Analysis).
class DrinkingAnalysisResult {
  const DrinkingAnalysisResult({
    required this.videoDurationMs,
    required this.framesExtracted,
    required this.faceDetectedFrames,
    required this.handDetectedFrames,
    required this.validDistanceFrames,
    required this.minDistance,
    required this.maxDistance,
    required this.nearMouthDetected,
    required this.approachDetected,
    required this.withdrawDetected,
    required this.sequenceCompleted,
    required this.confidenceScore,
    required this.level,
    required this.isAutoVerified,
    required this.reason,
    this.frameAnalyses = const <FrameAnalysis>[],
  });

  final int videoDurationMs;
  final int framesExtracted;
  final int faceDetectedFrames;
  final int handDetectedFrames;
  final int validDistanceFrames;
  final double? minDistance;
  final double? maxDistance;
  final bool nearMouthDetected;
  final bool approachDetected;
  final bool withdrawDetected;
  final bool sequenceCompleted;
  final double confidenceScore;
  final DrinkingConfidenceLevel level;
  final bool isAutoVerified;
  final String reason;
  final List<FrameAnalysis> frameAnalyses;

  /// String status untuk backend dan UI.
  String get statusLabel => switch (level) {
        DrinkingConfidenceLevel.high => 'AUTO VERIFIED',
        DrinkingConfidenceLevel.medium => 'NEEDS REVIEW',
        DrinkingConfidenceLevel.low => 'MANUAL REVIEW REQUIRED',
      };

  /// Mencetak ringkasan diagnostic ke console sesuai format wajib.
  void printDiagnosticSummary() {
    final String durationSec = (videoDurationMs / 1000.0).toStringAsFixed(1);
    final String nearStr = nearMouthDetected ? 'YES' : 'NO';
    final String approachStr = approachDetected ? 'YES' : 'NO';
    final String withdrawStr = withdrawDetected ? 'YES' : 'NO';
    final String seqStr = sequenceCompleted ? 'VALID' : 'INVALID';
    final String minDistStr = minDistance != null ? minDistance!.toStringAsFixed(3) : '-';
    final String maxDistStr = maxDistance != null ? maxDistance!.toStringAsFixed(3) : '-';
    final String scoreStr = '${confidenceScore.toStringAsFixed(1)}%';

    final String banner = '''
================================
[VOT VIDEO ANALYSIS]
================================
VIDEO:
duration=${durationSec}s

FRAMES EXTRACTED:
$framesExtracted

FACE DETECTED:
$faceDetectedFrames / $framesExtracted

HAND DETECTED:
$handDetectedFrames / $framesExtracted

VALID DISTANCE FRAMES:
$validDistanceFrames

MIN DISTANCE:
$minDistStr

MAX DISTANCE:
$maxDistStr

NEAR MOUTH:
$nearStr

APPROACH:
$approachStr

WITHDRAW:
$withdrawStr

SEQUENCE:
$seqStr

CONFIDENCE:
$scoreStr

RESULT:
$statusLabel

REASON:
$reason
================================
''';
    debugPrint(banner);
  }
}
