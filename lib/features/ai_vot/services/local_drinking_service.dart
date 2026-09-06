import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import '../models/vot_debug_state.dart';
import '../utils/camera_nv21_adapter.dart';
import '../utils/vot_diagnostic_tracker.dart';

/// MediaPipe lokal:
/// - Face Mesh untuk mendeteksi posisi mulut
/// - Hand Landmarker untuk mendeteksi posisi tangan
///
/// Semua proses dilakukan secara lokal.
/// Tidak mengirim frame ke server.
class LocalDrinkingService {
  LocalDrinkingService();

  FaceDetectorProcessor? _detector;
  FaceMeshProcessor? _mesh;
  FaceMeshInferencePipeline? _pipeline;

  HandLandmarkerPlugin? _hands;
  StreamSubscription<List<Hand>>? _handSub;

  List<Hand> _latestHands = const <Hand>[];

  DateTime _lastInference =
      DateTime.fromMillisecondsSinceEpoch(0);

  /// Waktu terakhir hand update.
  DateTime _lastHandUpdate =
      DateTime.fromMillisecondsSinceEpoch(0);

  bool _busy = false;
  bool _ready = false;

  /// Proses inference maksimal setiap 200ms.
  static const Duration _throttle =
      Duration(milliseconds: 200);

  /// Landmark FaceMesh.
  ///
  /// 13 = Upper Lip
  /// 14 = Lower Lip
  static const int _upperLip = 13;
  static const int _lowerLip = 14;

  /// Aktifkan untuk melihat hasil deteksi di terminal.
  static const bool debugDrinking = false;


  final VotSessionDiagnostic diagnostic = VotSessionDiagnostic();

  /// Debug notifier untuk on-screen debug overlay.
  final VotDebugNotifier debugNotifier = VotDebugNotifier();

  /// Expose lastHandUpdate untuk menghitung hand data age.
  DateTime get lastHandUpdate => _lastHandUpdate;

  /// Pastikan service sudah diinisialisasi.
  Future<void> ensureInitialized() async {
    if (_ready) return;

    await initialize();
  }

  /// Inisialisasi Face Mesh dan Hand Landmarker.
  Future<void> initialize() async {
    await dispose();

    try {
      /// Face Detector.
      _detector = await FaceDetectorProcessor.create();

      /// Face Mesh.
      _mesh = await FaceMeshProcessor.create(
        model: FaceMeshModel.v2,
      );

      /// Pipeline Face Detector + Face Mesh.
      _pipeline = FaceMeshInferencePipeline(
        detector: _detector!,
        mesh: _mesh!,
      );

      /// Hand Landmarker.
      _hands = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.cpu,
      );

      /// Hasil Hand Landmarker dikirim melalui stream.
      _handSub =
          _hands!.landmarkStream.listen(
        (List<Hand> hands) {
          _latestHands = hands;
          _lastHandUpdate = DateTime.now();
        },
      );

      _ready = true;
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  bool get isReady => _ready;

  /// Proses satu frame kamera.
  ///
  /// Menghasilkan:
  /// - faceVisible
  /// - handVisible
  /// - handMouthDistance
  DrinkingObservation? observeFrame({
    required CameraImage image,
    required int sensorOrientation,
    required bool frontCamera,
    required DateTime now,
  }) {
    if (!_ready ||
        _pipeline == null ||
        _hands == null) {
      return null;
    }

    /// Hindari proses inference bersamaan.
    if (_busy) return null;

    /// Throttle inference.
    if (now.difference(_lastInference) <
        _throttle) {
      return null;
    }

    _lastInference = now;
    _busy = true;

    try {
      // =====================================
      // 1. PROCESS HAND LANDMARKER
      // =====================================

      if (image.planes.length >= 3) {
        _hands!.processFrame(
          image,
          sensorOrientation,
        );
      }

      // =====================================
      // 2. CONVERT CAMERA IMAGE TO NV21
      // =====================================

      final FaceMeshNv21Image? nv21 =
          CameraNv21Adapter.toNv21(image);

      if (nv21 == null) {
        return DrinkingObservation(
          faceVisible: false,
          handVisible: _latestHands.isNotEmpty,
          handMouthDistance: null,
        );
      }

      // =====================================
      // 3. PROCESS FACE MESH
      // =====================================

      FaceMeshInferenceResult? inference;

      try {
        inference = _pipeline!.processNv21(
          nv21,
          rotationDegrees: sensorOrientation,

          /// FaceMesh coordinate akan mirror
          /// ketika menggunakan front camera.
          mirrorHorizontal: frontCamera,
        );
      } catch (_) {
        return DrinkingObservation(
          faceVisible: false,
          handVisible: _latestHands.isNotEmpty,
          handMouthDistance: null,
        );
      }

      // =====================================
      // 4. CHECK FACE
      // =====================================

      final FaceMeshResult? mesh =
          inference.meshResult;

      final bool faceVisible =
          mesh != null &&
          mesh.landmarks.length > _lowerLip;

      Offset? mouth;

      if (faceVisible) {
        final FaceMeshLandmark upper =
            mesh.landmarks[_upperLip];

        final FaceMeshLandmark lower =
            mesh.landmarks[_lowerLip];

        /// Titik mulut =
        /// tengah antara upper lip dan lower lip.
        mouth = Offset(
          (upper.x + lower.x) / 2,
          (upper.y + lower.y) / 2,
        );
      }

      // =====================================
      // 5. CHECK HAND
      // =====================================

      final bool handVisible =
          _latestHands.isNotEmpty;

      double? distance;
      _HandDistanceResult? handResult;

      if (faceVisible &&
          handVisible &&
          mouth != null) {
        handResult = _minHandDistanceWithInfo(
          _latestHands.first,
          mouth,
          frontCamera: frontCamera,
        );
        distance = handResult.distance;
      }

      // =====================================
      // 6. UPDATE DEBUG STATE + DIAGNOSTIC
      // =====================================

      final Duration handAge = now.difference(_lastHandUpdate);
      final bool handStale = handVisible && handAge.inMilliseconds > 500;

      diagnostic.recordFrame(
        faceVisible: faceVisible,
        handVisible: handVisible,
        distance: distance,
      );

      // Update debug notifier (hanya mutate, tanpa setState).
      debugNotifier.update((VotDebugState s) {
        s.totalFrames++;
        s.lastFrameTime = now;
        s.faceDetected = faceVisible;
        s.handDetected = handVisible;
        s.frontCamera = frontCamera;
        s.handMirrorApplied = frontCamera;

        if (faceVisible) {
          s.faceFrameCount++;
          s.lastFaceDetection = now;
          s.mouthX = mouth?.dx;
          s.mouthY = mouth?.dy;
        } else {
          s.faceLost = true;
        }

        if (handVisible) {
          s.handFrameCount++;
          s.lastHandDetection = _lastHandUpdate;
          s.handDataAge = handAge;
          s.handDataStale = handStale;
        } else {
          s.handLost = true;
        }

        // Fingertip coordinates.
        if (handResult != null) {
          s.thumbTipX = handResult.thumbX;
          s.thumbTipY = handResult.thumbY;
          s.thumbTipRawX = handResult.thumbRawX;
          s.indexTipX = handResult.indexX;
          s.indexTipY = handResult.indexY;
          s.indexTipRawX = handResult.indexRawX;
          s.middleTipX = handResult.middleX;
          s.middleTipY = handResult.middleY;
          s.middleTipRawX = handResult.middleRawX;
          s.closestTipIndex = handResult.closestIndex;
        } else {
          s.thumbTipX = null;
          s.thumbTipY = null;
          s.thumbTipRawX = null;
          s.indexTipX = null;
          s.indexTipY = null;
          s.indexTipRawX = null;
          s.middleTipX = null;
          s.middleTipY = null;
          s.middleTipRawX = null;
        }

        s.distance = distance;
        if (distance != null) {
          s.minDistance = s.minDistance == null
              ? distance
              : math.min(s.minDistance!, distance);
          s.maxDistance = s.maxDistance == null
              ? distance
              : math.max(s.maxDistance!, distance);
        } else {
          s.distanceNull = true;
        }

        // Check stalled camera stream.
        if (s.lastFrameTime != null) {
          s.cameraStreamStalled =
              now.difference(s.lastFrameTime!).inMilliseconds > 1000;
        }
      });

      // =====================================
      // 7. RETURN OBSERVATION
      // =====================================

      return DrinkingObservation(
        faceVisible: faceVisible,
        handVisible: handVisible,
        handMouthDistance: distance,
        mouthX: mouth?.dx,
        mouthY: mouth?.dy,
      );
    } finally {
      _busy = false;
    }
  }

  // =========================================
  // HAND DISTANCE WITH TIP INFO
  // =========================================



  // =========================================
  // HAND TO MOUTH DISTANCE
  // =========================================

  static _HandDistanceResult _minHandDistanceWithInfo(
    Hand hand,
    Offset mouth, {
    required bool frontCamera,
  }) {
    double best = double.infinity;
    int bestIndex = 8;

    double? thumbX, thumbY, thumbRawX;
    double? indexX, indexY, indexRawX;
    double? middleX, middleY, middleRawX;

    /// Landmark yang relevan.
    ///
    /// Thumb Tip  = 4
    /// Index Tip  = 8
    /// Middle Tip = 12
    const List<int> relevantTips = [4, 8, 12];

    for (final int index in relevantTips) {
      if (hand.landmarks.length <= index) continue;

      final Landmark point = hand.landmarks[index];

      /// Mirror X agar sesuai dengan FaceMesh.
      final double mirroredX =
          frontCamera ? 1.0 - point.x : point.x;
      final double y = point.y;

      // Store per-tip coordinates.
      if (index == 4) {
        thumbX = mirroredX;
        thumbY = y;
        thumbRawX = point.x;
      } else if (index == 8) {
        indexX = mirroredX;
        indexY = y;
        indexRawX = point.x;
      } else if (index == 12) {
        middleX = mirroredX;
        middleY = y;
        middleRawX = point.x;
      }

      final double dx = mirroredX - mouth.dx;
      final double dy = y - mouth.dy;
      final double d = math.sqrt(dx * dx + dy * dy);

      if (d < best) {
        best = d;
        bestIndex = index;
      }
    }

    return _HandDistanceResult(
      distance: best,
      closestIndex: bestIndex,
      thumbX: thumbX,
      thumbY: thumbY,
      thumbRawX: thumbRawX,
      indexX: indexX,
      indexY: indexY,
      indexRawX: indexRawX,
      middleX: middleX,
      middleY: middleY,
      middleRawX: middleRawX,
    );
  }

  // =========================================
  // DISPOSE
  // =========================================

  Future<void> dispose() async {
    _ready = false;

    await _handSub?.cancel();

    _handSub = null;

    _hands?.dispose();

    _hands = null;

    _pipeline = null;

    _mesh?.close();

    _mesh = null;

    _detector?.close();

    _detector = null;

    _latestHands =
        const <Hand>[];
  }
}

// ===========================================
// DRINKING OBSERVATION
// ===========================================

class DrinkingObservation {
  const DrinkingObservation({
    required this.faceVisible,
    required this.handVisible,
    required this.handMouthDistance,
    this.mouthX,
    this.mouthY,
  });

  final bool faceVisible;
  final bool handVisible;
  final double? handMouthDistance;
  final double? mouthX;
  final double? mouthY;
}

/// Internal: hasil perhitungan jarak tangan-mulut beserta koordinat tip.
class _HandDistanceResult {
  const _HandDistanceResult({
    required this.distance,
    required this.closestIndex,
    this.thumbX,
    this.thumbY,
    this.thumbRawX,
    this.indexX,
    this.indexY,
    this.indexRawX,
    this.middleX,
    this.middleY,
    this.middleRawX,
  });

  final double distance;
  final int closestIndex;
  final double? thumbX;
  final double? thumbY;
  final double? thumbRawX;
  final double? indexX;
  final double? indexY;
  final double? indexRawX;
  final double? middleX;
  final double? middleY;
  final double? middleRawX;
}