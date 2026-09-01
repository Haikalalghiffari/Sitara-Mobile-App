import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

import '../utils/camera_nv21_adapter.dart';

/// MediaPipe lokal: Face Landmarker (mesh v2) + Hand Landmarker.
///
/// Tidak mengirim frame ke server. Tidak mengklaim obat tertelan.
class LocalDrinkingService {
  LocalDrinkingService();

  FaceDetectorProcessor? _detector;
  FaceMeshProcessor? _mesh;
  FaceMeshInferencePipeline? _pipeline;
  HandLandmarkerPlugin? _hands;
  StreamSubscription<List<Hand>>? _handSub;

  List<Hand> _latestHands = const <Hand>[];
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  bool _ready = false;

  static const Duration _throttle = Duration(milliseconds: 200);
  static const int _upperLip = 13;
  static const int _lowerLip = 14;

  Future<void> ensureInitialized() async {
    if (_ready) return;
    await initialize();
  }

  Future<void> initialize() async {
    await dispose();
    try {
      _detector = await FaceDetectorProcessor.create();
      _mesh = await FaceMeshProcessor.create(model: FaceMeshModel.v2);
      _pipeline = FaceMeshInferencePipeline(
        detector: _detector!,
        mesh: _mesh!,
      );
      _hands = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.cpu,
      );
      _handSub = _hands!.landmarkStream.listen((List<Hand> hands) {
        _latestHands = hands;
      });
      _ready = true;
    } catch (_) {
      await dispose();
      rethrow;
    }
  }

  bool get isReady => _ready;

  DrinkingObservation? observeFrame({
    required CameraImage image,
    required int sensorOrientation,
    required bool frontCamera,
    required DateTime now,
  }) {
    if (!_ready || _pipeline == null || _hands == null) return null;
    if (_busy) return null;
    if (now.difference(_lastInference) < _throttle) return null;

    _lastInference = now;
    _busy = true;
    try {
      if (image.planes.length >= 3) {
        _hands!.processFrame(image, sensorOrientation);
      }

      final FaceMeshNv21Image? nv21 = CameraNv21Adapter.toNv21(image);
      if (nv21 == null) {
        return DrinkingObservation(
          faceVisible: false,
          handVisible: _latestHands.isNotEmpty,
          handMouthDistance: null,
        );
      }

      FaceMeshInferenceResult? inference;
      try {
        inference = _pipeline!.processNv21(
          nv21,
          rotationDegrees: sensorOrientation,
          mirrorHorizontal: frontCamera,
        );
      } catch (_) {
        return DrinkingObservation(
          faceVisible: false,
          handVisible: _latestHands.isNotEmpty,
          handMouthDistance: null,
        );
      }
      final FaceMeshResult? mesh = inference.meshResult;
      final bool faceVisible =
          mesh != null && mesh.landmarks.length > _lowerLip;

      Offset? mouth;
      if (faceVisible) {
        final FaceMeshLandmark upper = mesh.landmarks[_upperLip];
        final FaceMeshLandmark lower = mesh.landmarks[_lowerLip];
        mouth = Offset(
          (upper.x + lower.x) / 2,
          (upper.y + lower.y) / 2,
        );
      }

      final bool handVisible = _latestHands.isNotEmpty;
      double? distance;
      if (faceVisible && handVisible && mouth != null) {
        distance = _minHandDistance(_latestHands.first, mouth);
      }

      return DrinkingObservation(
        faceVisible: faceVisible,
        handVisible: handVisible,
        handMouthDistance: distance,
      );
    } finally {
      _busy = false;
    }
  }

  static double _minHandDistance(Hand hand, Offset mouth) {
    double best = double.infinity;
    for (final Landmark point in hand.landmarks) {
      final double dx = point.x - mouth.dx;
      final double dy = point.y - mouth.dy;
      best = math.min(best, math.sqrt(dx * dx + dy * dy));
    }
    return best;
  }

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
    _latestHands = const <Hand>[];
  }
}

class DrinkingObservation {
  const DrinkingObservation({
    required this.faceVisible,
    required this.handVisible,
    required this.handMouthDistance,
  });

  final bool faceVisible;
  final bool handVisible;
  final double? handMouthDistance;
}
