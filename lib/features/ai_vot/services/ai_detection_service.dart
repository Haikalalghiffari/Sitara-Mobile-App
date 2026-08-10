import '../models/detection_result.dart';

/// Deteksi wajah pasien.
///
/// Rencana implementasi: pretrained model on-device.
abstract interface class FaceDetectionService {
  Future<FaceDetectionResult> detect(VerificationFrame frame);
  Future<void> dispose();
}

/// Deteksi obat yang diperlihatkan pasien.
///
/// Rencana implementasi: model yang di-train atau di-fine-tune sendiri
/// agar mengenali obat yang dipakai pasien SITARA.
abstract interface class MedicineDetectionService {
  Future<MedicineDetectionResult> detect(VerificationFrame frame);
  Future<void> dispose();
}

/// Estimasi pose untuk menilai posisi tangan terhadap wajah.
///
/// Rencana implementasi: pretrained pose model on-device.
abstract interface class PoseDetectionService {
  Future<PoseDetectionResult> detect(VerificationFrame frame);
  Future<void> dispose();
}

/// Menilai rangkaian gerakan minum obat dari kombinasi hasil deteksi.
///
/// Menggunakan temporal logic, bukan action recognition, sesuai rencana
/// tahap pertama.
abstract interface class DrinkingSequenceAnalyzer {
  DrinkingSequenceStage evaluate({
    required FaceDetectionResult face,
    required MedicineDetectionResult medicine,
    required PoseDetectionResult pose,
  });

  void reset();
}
