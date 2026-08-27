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

  /// MediaPipe COMPLETED lokal → COMPLETING, bukan final COMPLETED.
  static VerificationState afterLocalDrinkingCompleted() {
    return VerificationState.completing;
  }

  static bool isServerVerified({
    required String status,
    required String votStep,
  }) {
    return status == 'verified' && votStep == 'verified';
  }

  /// Body `POST /vot/complete`. Null jika ID sesi tidak ada — jangan request.
  static Map<String, Object>? completeRequestBody(int? dailyMedicationId) {
    if (dailyMedicationId == null || dailyMedicationId <= 0) return null;
    return <String, Object>{
      'daily_medication_id': dailyMedicationId,
      'drinking_verified': true,
    };
  }

  static VerificationState afterComplete({required bool serverVerified}) {
    return serverVerified
        ? VerificationState.completed
        : VerificationState.completing;
  }

  /// Timeout/gagal minum: tetap DRINKING agar face+obat tidak diulang.
  static VerificationState afterDrinkingTimeout() {
    return VerificationState.drinking;
  }

  static VerificationState afterDrinkingRetry() {
    return VerificationState.drinking;
  }

  /// Langkah yang boleh diulang dari state error saat ini.
  static VotRetryTarget? retryTarget({
    required VerificationState state,
    required bool phaseError,
  }) {
    if (!phaseError) return null;
    return switch (state) {
      VerificationState.faceVerifying => VotRetryTarget.face,
      VerificationState.medicineDetecting => VotRetryTarget.medicine,
      VerificationState.drinking => VotRetryTarget.drinking,
      VerificationState.completing => VotRetryTarget.complete,
      _ => null,
    };
  }
}

enum VotRetryTarget { face, medicine, drinking, complete }
