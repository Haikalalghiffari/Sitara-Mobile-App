import 'package:flutter/foundation.dart';

/// Data debug realtime untuk VOT drinking detection.
///
/// Menggunakan [ValueNotifier] agar widget debug bisa rebuild
/// tanpa memicu setState pada halaman utama.
class VotDebugState {
  // ── Camera ──
  bool streamActive;
  String cameraResolution;
  String cameraLens;
  int sensorOrientation;
  bool recording;

  // ── Face ──
  bool faceDetected;
  int faceFrameCount;
  DateTime? lastFaceDetection;
  double? mouthX;
  double? mouthY;

  // ── Hand ──
  bool handDetected;
  int handFrameCount;
  DateTime? lastHandDetection;
  Duration handDataAge;
  bool handDataStale;
  bool handMirrorApplied;

  // ── Fingertip coordinates (after mirror transform) ──
  double? thumbTipX;
  double? thumbTipY;
  double? indexTipX;
  double? indexTipY;
  double? middleTipX;
  double? middleTipY;

  // ── Raw fingertip coordinates (before mirror) ──
  double? thumbTipRawX;
  double? indexTipRawX;
  double? middleTipRawX;

  // ── Distance ──
  double? distance;
  double? minDistance;
  double? maxDistance;
  double nearThreshold;
  double farThreshold;
  bool nearReached;
  bool farReached;
  bool withdrawingDetected;

  // ── State machine ──
  String currentStage;
  String maxStage;
  bool sequenceCompleted;

  // ── Frame ──
  int totalFrames;
  DateTime? lastFrameTime;
  bool cameraStreamStalled;

  // ── Flags ──
  bool faceLost;
  bool handLost;
  bool distanceNull;
  bool timedOut;
  bool frontCamera;

  // ── Diagnostic ──
  String diagnosticReason;

  // ── Closest tip index for visual line ──
  int closestTipIndex; // 4, 8, or 12

  VotDebugState({
    this.streamActive = false,
    this.cameraResolution = '-',
    this.cameraLens = '-',
    this.sensorOrientation = 0,
    this.recording = false,
    this.faceDetected = false,
    this.faceFrameCount = 0,
    this.lastFaceDetection,
    this.mouthX,
    this.mouthY,
    this.handDetected = false,
    this.handFrameCount = 0,
    this.lastHandDetection,
    this.handDataAge = Duration.zero,
    this.handDataStale = false,
    this.handMirrorApplied = false,
    this.thumbTipX,
    this.thumbTipY,
    this.indexTipX,
    this.indexTipY,
    this.middleTipX,
    this.middleTipY,
    this.thumbTipRawX,
    this.indexTipRawX,
    this.middleTipRawX,
    this.distance,
    this.minDistance,
    this.maxDistance,
    this.nearThreshold = 0.22,
    this.farThreshold = 0.34,
    this.nearReached = false,
    this.farReached = false,
    this.withdrawingDetected = false,
    this.currentStage = 'waiting',
    this.maxStage = 'waiting',
    this.sequenceCompleted = false,
    this.totalFrames = 0,
    this.lastFrameTime,
    this.cameraStreamStalled = false,
    this.faceLost = false,
    this.handLost = false,
    this.distanceNull = false,
    this.timedOut = false,
    this.frontCamera = true,
    this.diagnosticReason = '',
    this.closestTipIndex = 8,
  });
}

/// ValueNotifier global untuk debug state VOT.
///
/// Widget debug melakukan `ValueListenableBuilder` pada notifier ini,
/// sehingga hanya widget debug yang rebuild setiap frame,
/// bukan seluruh AiVotPage.
class VotDebugNotifier extends ValueNotifier<VotDebugState> {
  VotDebugNotifier() : super(VotDebugState());

  /// Update state dan notify listeners.
  void update(void Function(VotDebugState state) mutate) {
    mutate(value);
    notifyListeners();
  }
}
