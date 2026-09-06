import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

/// Data representasi satu frame hasil ekstraksi video lokal beserta metadata deteksi tangan native.
class ExtractedVideoFrame {
  const ExtractedVideoFrame({
    required this.path,
    required this.timestampMs,
    this.width = 0,
    this.height = 0,
    this.handDetected = false,
    this.thumbTipX,
    this.thumbTipY,
    this.indexTipX,
    this.indexTipY,
    this.middleTipX,
    this.middleTipY,
  });

  final String path;
  final int timestampMs;
  final int width;
  final int height;
  final bool handDetected;

  // Koordinat ternormalisasi (0.0 .. 1.0) langsung dari Native MediaPipe
  final double? thumbTipX;
  final double? thumbTipY;
  final double? indexTipX;
  final double? indexTipY;
  final double? middleTipX;
  final double? middleTipY;

  factory ExtractedVideoFrame.fromMap(Map<dynamic, dynamic> map) {
    return ExtractedVideoFrame(
      path: map['path']?.toString() ?? '',
      timestampMs: (map['timestampMs'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      handDetected: map['handDetected'] as bool? ?? false,
      thumbTipX: (map['thumbTipX'] as num?)?.toDouble(),
      thumbTipY: (map['thumbTipY'] as num?)?.toDouble(),
      indexTipX: (map['indexTipX'] as num?)?.toDouble(),
      indexTipY: (map['indexTipY'] as num?)?.toDouble(),
      middleTipX: (map['middleTipX'] as num?)?.toDouble(),
      middleTipY: (map['middleTipY'] as num?)?.toDouble(),
    );
  }

  File get file => File(path);

  bool get exists => File(path).existsSync();

  /// Menghitung jarak normalized Euclidean terdekat antara ujung jari tangan dan posisi mulut (Offset(mouthX, mouthY)).
  /// Karena kedua model menggunakan sistem koordinat unmirrored identik [0.0, 1.0], perhitungan langsung Euclidean valid.
  double? minDistanceToMouth(ui.Offset mouth) {
    if (!handDetected) return null;

    final List<ui.Offset> tips = <ui.Offset>[];
    if (thumbTipX != null && thumbTipY != null) {
      tips.add(ui.Offset(thumbTipX!, thumbTipY!));
    }
    if (indexTipX != null && indexTipY != null) {
      tips.add(ui.Offset(indexTipX!, indexTipY!));
    }
    if (middleTipX != null && middleTipY != null) {
      tips.add(ui.Offset(middleTipX!, middleTipY!));
    }

    if (tips.isEmpty) return null;

    double minD = double.infinity;
    for (final ui.Offset tip in tips) {
      final double dx = tip.dx - mouth.dx;
      final double dy = tip.dy - mouth.dy;
      final double d = math.sqrt(dx * dx + dy * dy);
      if (d < minD) {
        minD = d;
      }
    }

    return minD.isFinite ? minD : null;
  }

  @override
  String toString() =>
      'ExtractedVideoFrame(path: $path, timestampMs: $timestampMs, ${width}x$height, hand: $handDetected)';
}

/// Hasil validasi keselarasan sistem koordinat antara Native HandLandmarker dan Dart FaceMesh pada 1 frame identik.
class CoordinateValidationResult {
  const CoordinateValidationResult({
    required this.framePath,
    required this.timestampMs,
    required this.frameWidth,
    required this.frameHeight,
    required this.handDetected,
    required this.faceDetected,
    this.thumbTip,
    this.indexTip,
    this.middleTip,
    this.mouthPosition,
    this.handMouthDistance,
    required this.handNormalized,
    required this.faceNormalized,
    required this.hasRotation,
    required this.hasMirror,
    required this.coordinateSystemCompatible,
    this.notes = '',
  });

  final String framePath;
  final int timestampMs;
  final int frameWidth;
  final int frameHeight;
  final bool handDetected;
  final bool faceDetected;
  final ui.Offset? thumbTip;
  final ui.Offset? indexTip;
  final ui.Offset? middleTip;
  final ui.Offset? mouthPosition;
  final double? handMouthDistance;
  final bool handNormalized;
  final bool faceNormalized;
  final bool hasRotation;
  final bool hasMirror;
  final bool coordinateSystemCompatible;
  final String notes;

  String formatDiagnostic() {
    final String thumbStr = thumbTip != null
        ? '(${thumbTip!.dx.toStringAsFixed(3)}, ${thumbTip!.dy.toStringAsFixed(3)})'
        : 'null';
    final String indexStr = indexTip != null
        ? '(${indexTip!.dx.toStringAsFixed(3)}, ${indexTip!.dy.toStringAsFixed(3)})'
        : 'null';
    final String middleStr = middleTip != null
        ? '(${middleTip!.dx.toStringAsFixed(3)}, ${middleTip!.dy.toStringAsFixed(3)})'
        : 'null';
    final String mouthXStr = mouthPosition != null
        ? mouthPosition!.dx.toStringAsFixed(3)
        : 'null';
    final String mouthYStr = mouthPosition != null
        ? mouthPosition!.dy.toStringAsFixed(3)
        : 'null';
    final String distStr = handMouthDistance != null
        ? handMouthDistance!.toStringAsFixed(3)
        : 'null';

    return '''
FRAME:
width=$frameWidth
height=$frameHeight

HAND:
thumb=$thumbStr
index=$indexStr
middle=$middleStr

MOUTH:
x=$mouthXStr
y=$mouthYStr

DISTANCE:
$distStr
''';
  }

  Map<String, dynamic> toDiagnosticMap() {
    return <String, dynamic>{
      'FRAME': <String, dynamic>{
        'path': framePath,
        'timestampMs': timestampMs,
        'width': frameWidth,
        'height': frameHeight,
      },
      'HAND': <String, dynamic>{
        'detected': handDetected,
        'thumbTip': thumbTip != null ? '${thumbTip!.dx.toStringAsFixed(3)}, ${thumbTip!.dy.toStringAsFixed(3)}' : null,
        'indexTip': indexTip != null ? '${indexTip!.dx.toStringAsFixed(3)}, ${indexTip!.dy.toStringAsFixed(3)}' : null,
        'middleTip': middleTip != null ? '${middleTip!.dx.toStringAsFixed(3)}, ${middleTip!.dy.toStringAsFixed(3)}' : null,
      },
      'FACE': <String, dynamic>{
        'detected': faceDetected,
        'mouthX': mouthPosition?.dx.toStringAsFixed(3),
        'mouthY': mouthPosition?.dy.toStringAsFixed(3),
      },
      'COORDINATE': <String, dynamic>{
        'handNormalized_0_1': handNormalized,
        'faceNormalized_0_1': faceNormalized,
        'hasRotation': hasRotation,
        'hasMirror': hasMirror,
        'coordinateSystemCompatible': coordinateSystemCompatible,
        'distance': handMouthDistance?.toStringAsFixed(3),
      },
      'notes': notes,
    };
  }
}

/// Utility untuk mengekstrak frame dari video MP4 hasil rekaman secara efisien
/// melalui native Android MediaMetadataRetriever via MethodChannel.
class VideoFrameExtractor {
  const VideoFrameExtractor();

  static const MethodChannel _channel = MethodChannel('sitara/video_analysis');

  /// Uji coba panggil prototype native HandLandmarker di Android.
  Future<Map<String, dynamic>> testNativeHandLandmarker({String? videoPath}) async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMapMethod<dynamic, dynamic>(
        'testNativeHandLandmarker',
        <String, dynamic>{
          'videoPath': ?videoPath,
        },
      );
      return res != null ? Map<String, dynamic>.from(res) : <String, dynamic>{'success': false, 'error': 'Null response'};
    } catch (e) {
      return <String, dynamic>{'success': false, 'error': e.toString()};
    }
  }

  /// Mengekstrak sejumlah [sampleCount] frame dari file video [videoPath].
  ///
  /// Mengembalikan list [ExtractedVideoFrame] berurutan berdasarkan timestamp.
  Future<List<ExtractedVideoFrame>> extractFrames({
    required String videoPath,
    int sampleCount = 15,
  }) async {
    final File videoFile = File(videoPath);
    if (!videoFile.existsSync()) {
      debugPrint('[VideoFrameExtractor] File video tidak ditemukan di: $videoPath');
      return const <ExtractedVideoFrame>[];
    }

    try {
      final List<dynamic>? rawList = await _channel.invokeListMethod<dynamic>(
        'extractFrames',
        <String, dynamic>{
          'videoPath': videoPath,
          'sampleCount': sampleCount,
        },
      );

      if (rawList == null || rawList.isEmpty) {
        debugPrint('[VideoFrameExtractor] MediaMetadataRetriever tidak menghasilkan frame.');
        return const <ExtractedVideoFrame>[];
      }

      final List<ExtractedVideoFrame> frames = <ExtractedVideoFrame>[];
      for (final dynamic item in rawList) {
        if (item is Map) {
          final ExtractedVideoFrame frame = ExtractedVideoFrame.fromMap(item);
          if (frame.path.isNotEmpty && frame.exists) {
            frames.add(frame);
          }
        }
      }

      // Pastikan urut kronologis berdasarkan timestampMs
      frames.sort((ExtractedVideoFrame a, ExtractedVideoFrame b) =>
          a.timestampMs.compareTo(b.timestampMs));

      return frames;
    } on PlatformException catch (e) {
      debugPrint('[VideoFrameExtractor] PlatformException: ${e.code} - ${e.message}');
      return const <ExtractedVideoFrame>[];
    } catch (e) {
      debugPrint('[VideoFrameExtractor] Unexpected error extracting frames: $e');
      return const <ExtractedVideoFrame>[];
    }
  }

  /// Validasi single frame: mengevaluasi keselarasan sistem koordinat antara
  /// Native HandLandmarker dan Dart FaceMesh pada 1 frame identik.
  Future<CoordinateValidationResult> validateSingleFrame({
    required ExtractedVideoFrame frame,
    required FaceMeshInferencePipeline facePipeline,
  }) async {
    final File file = frame.file;
    if (!file.existsSync()) {
      return CoordinateValidationResult(
        framePath: frame.path,
        timestampMs: frame.timestampMs,
        frameWidth: frame.width,
        frameHeight: frame.height,
        handDetected: false,
        faceDetected: false,
        handNormalized: false,
        faceNormalized: false,
        hasRotation: false,
        hasMirror: false,
        coordinateSystemCompatible: false,
        notes: 'File frame tidak ditemukan di disk',
      );
    }

    // 1. Decode JPEG yang sama ke RGBA buffer untuk FaceMesh di Dart
    final Uint8List bytes = await file.readAsBytes();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(buffer);
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image uiImage = frameInfo.image;
    final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);

    bool faceDetected = false;
    ui.Offset? mouth;

    if (byteData != null) {
      final FaceMeshImage faceImage = FaceMeshImage(
        pixels: byteData.buffer.asUint8List(),
        width: uiImage.width,
        height: uiImage.height,
        bytesPerRow: uiImage.width * 4,
        pixelFormat: 0, // RGBA
      );

      // Single source of truth: tanpa rotasi dan tanpa mirror horizontal!
      final FaceMeshInferenceResult inference = facePipeline.process(
        faceImage,
        rotationDegrees: 0,
        mirrorHorizontal: false,
      );

      final FaceMeshResult? mesh = inference.meshResult;
      if (mesh != null && mesh.landmarks.length > 14) {
        faceDetected = true;
        final FaceMeshLandmark upper = mesh.landmarks[13];
        final FaceMeshLandmark lower = mesh.landmarks[14];
        mouth = ui.Offset((upper.x + lower.x) / 2, (upper.y + lower.y) / 2);
      }
    }

    buffer.dispose();
    descriptor.dispose();
    uiImage.dispose();

    // 2. Evaluasi koordinat Hand & Face
    final bool handNorm = frame.handDetected
        ? (frame.thumbTipX != null && frame.thumbTipX! >= 0.0 && frame.thumbTipX! <= 1.0)
        : true;
    final bool faceNorm = faceDetected
        ? (mouth != null && mouth.dx >= 0.0 && mouth.dx <= 1.0 && mouth.dy >= 0.0 && mouth.dy <= 1.0)
        : true;

    double? distance;
    if (mouth != null && frame.handDetected) {
      distance = frame.minDistanceToMouth(mouth);
    }

    // Koordinat kompatibel jika keduanya ternormalisasi 0..1 pada frame yang sama tanpa transformasi terpisah
    final bool compatible = handNorm && faceNorm && (frame.width > 0 && frame.height > 0);

    return CoordinateValidationResult(
      framePath: frame.path,
      timestampMs: frame.timestampMs,
      frameWidth: frame.width,
      frameHeight: frame.height,
      handDetected: frame.handDetected,
      faceDetected: faceDetected,
      thumbTip: (frame.thumbTipX != null && frame.thumbTipY != null)
          ? ui.Offset(frame.thumbTipX!, frame.thumbTipY!)
          : null,
      indexTip: (frame.indexTipX != null && frame.indexTipY != null)
          ? ui.Offset(frame.indexTipX!, frame.indexTipY!)
          : null,
      middleTip: (frame.middleTipX != null && frame.middleTipY != null)
          ? ui.Offset(frame.middleTipX!, frame.middleTipY!)
          : null,
      mouthPosition: mouth,
      handMouthDistance: distance,
      handNormalized: handNorm,
      faceNormalized: faceNorm,
      hasRotation: false,
      hasMirror: false,
      coordinateSystemCompatible: compatible,
      notes: compatible
          ? 'Hand dan Face berada pada ruang koordinat unmirrored normal [0.0..1.0] yang identik.'
          : 'Inkonsistensi dimensi atau koordinat frame.',
    );
  }

  /// Membersihkan seluruh frame temporary di direktori cache setelah analisis selesai.
  Future<bool> clearFrames(List<ExtractedVideoFrame>? frames) async {
    bool allCleaned = true;

    // Bersihkan file lokal jika list frame diberikan
    if (frames != null && frames.isNotEmpty) {
      for (final ExtractedVideoFrame frame in frames) {
        try {
          final File f = frame.file;
          if (f.existsSync()) {
            f.deleteSync();
          }
        } catch (_) {
          allCleaned = false;
        }
      }
    }

    // Panggil native cleanup untuk memastikan seluruh folder cache/vot_frames bersih
    try {
      final bool? result = await _channel.invokeMethod<bool>('clearFrames');
      return (result ?? false) && allCleaned;
    } catch (_) {
      return allCleaned;
    }
  }
}
