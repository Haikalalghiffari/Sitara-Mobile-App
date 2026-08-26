import '../models/verification_state.dart';

/// Transisi UI setelah hasil backend, tanpa membuat ID sendiri.
class VotFlow {
  const VotFlow._();

  static VerificationState afterStart({required String votStep}) {
    return switch (votStep) {
      'face_verified' => VerificationState.medicineDetecting,
      'medicine_matched' || 'drinking' => VerificationState.drinking,
      'verified' => VerificationState.completed,
      _ => VerificationState.faceVerifying,
    };
  }

  static VerificationState afterFaceVerify({required bool verified}) {
    return verified
        ? VerificationState.faceVerified
        : VerificationState.faceVerifying;
  }

  static VerificationState afterMedicineDetect({required bool medicineMatch}) {
    return medicineMatch
        ? VerificationState.medicineMatched
        : VerificationState.medicineDetecting;
  }

  static VerificationState afterSession({required String votStep}) {
    return afterStart(votStep: votStep);
  }
}
