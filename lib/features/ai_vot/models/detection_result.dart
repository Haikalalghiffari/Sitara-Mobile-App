import 'dart:ui' show Offset, Rect;

/// Placeholder satu frame kamera.
///
/// Nanti tipe ini digantikan oleh `CameraImage` dari package `camera`
/// ketika dependency kamera sudah diaktifkan.
class VerificationFrame {
  const VerificationFrame({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final List<int> bytes;
}

/// Hasil deteksi wajah (rencana: pretrained model).
class FaceDetectionResult {
  const FaceDetectionResult({
    required this.faceDetected,
    required this.confidence,
    this.boundingBox,
  });

  const FaceDetectionResult.empty()
      : faceDetected = false,
        confidence = 0,
        boundingBox = null;

  final bool faceDetected;
  final double confidence;
  final Rect? boundingBox;
}

/// Hasil deteksi obat (rencana: model yang di-train sendiri oleh SITARA).
class MedicineDetectionResult {
  const MedicineDetectionResult({
    required this.medicineDetected,
    required this.confidence,
    this.boundingBox,
    this.medicineLabel,
  });

  const MedicineDetectionResult.empty()
      : medicineDetected = false,
        confidence = 0,
        boundingBox = null,
        medicineLabel = null;

  final bool medicineDetected;
  final double confidence;
  final Rect? boundingBox;
  final String? medicineLabel;
}

/// Keypoint yang dibutuhkan untuk menilai gerakan minum obat.
enum PoseKeypoint {
  nose,
  leftWrist,
  rightWrist,
  leftShoulder,
  rightShoulder,
}

/// Hasil pose estimation (rencana: pretrained model).
class PoseDetectionResult {
  const PoseDetectionResult({
    required this.keypoints,
    required this.confidence,
  });

  const PoseDetectionResult.empty()
      : keypoints = const {},
        confidence = 0;

  final Map<PoseKeypoint, Offset> keypoints;
  final double confidence;
}

/// Tahap temporal untuk menilai aktivitas minum obat.
///
/// Urutan yang diharapkan: tangan menjauh dari obat, mendekat, obat dibawa
/// ke arah wajah, obat dekat mulut, lalu tangan menjauh kembali.
enum DrinkingSequenceStage {
  idle,
  detectingFace,
  detectingMedicine,
  handApproachingMedicine,
  medicineNearFace,
  verificationComplete,
  verificationFailed,
}
