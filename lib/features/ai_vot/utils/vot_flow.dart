import '../models/verification_state.dart';

/// Transisi UI setelah hasil backend, tanpa membuat ID sendiri.
class VotFlow {
  const VotFlow._();

  static VerificationState afterStart({required String votStep, String? status}) {
    if (status?.toLowerCase() == 'needs_review') {
      return VerificationState.needsReview;
    }
    return switch (votStep) {
      'face_verified' => VerificationState.medicineDetecting,
      'medicine_matched' || 'drinking' => VerificationState.drinking,
      'verified' => VerificationState.completed,
      _ => VerificationState.faceVerifying,
    };
  }

  static VerificationState afterFaceVerify({
    required bool verified,
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    if (verified) return VerificationState.faceVerified;
    if (isNeedsReview || !canRetry) return VerificationState.needsReview;
    return VerificationState.faceVerifying;
  }

  static VerificationState afterMedicineDetect({
    required bool medicineMatch,
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    if (medicineMatch) return VerificationState.medicineMatched;
    if (isNeedsReview || !canRetry) return VerificationState.needsReview;
    return VerificationState.medicineDetecting;
  }

  static VerificationState afterSession({
    required String votStep,
    String? status,
  }) {
    return afterStart(votStep: votStep, status: status);
  }

  /// MediaPipe COMPLETED lokal -> COMPLETING, bukan final COMPLETED.
  static VerificationState afterLocalDrinkingCompleted() {
    return VerificationState.completing;
  }

  static bool isServerVerified({
    required String status,
    required String votStep,
  }) {
    return status == 'verified' && votStep == 'verified';
  }

  /// Body `POST /vot/complete`. Null jika ID sesi tidak ada - jangan request.
  static Map<String, Object>? completeRequestBody(
    int? dailyMedicationId, {
    bool drinkingVerified = true,
    String? maxDrinkingStage,
    String? failureReason,
  }) {
    if (dailyMedicationId == null || dailyMedicationId <= 0) return null;
    final Map<String, Object> body = <String, Object>{
      'daily_medication_id': dailyMedicationId,
      'drinking_verified': drinkingVerified,
    };
    if (maxDrinkingStage != null && maxDrinkingStage.isNotEmpty) {
      body['max_drinking_stage'] = maxDrinkingStage;
    }
    if (failureReason != null && failureReason.isNotEmpty) {
      body['failure_reason'] = failureReason;
    }
    return body;
  }

  static VerificationState afterComplete({
    required bool serverVerified,
    bool isNeedsReview = false,
    bool canRetry = false,
  }) {
    if (serverVerified) return VerificationState.completed;
    if (isNeedsReview) return VerificationState.needsReview;
    if (canRetry) return VerificationState.drinking;
    return VerificationState.completing;
  }

  /// Timeout/gagal minum: tetap DRINKING agar face+obat tidak diulang.
  static VerificationState afterDrinkingTimeout({
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    if (isNeedsReview || !canRetry) return VerificationState.needsReview;
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
