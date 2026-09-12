import '../models/verification_state.dart';

/// `needsReview` hanya untuk video analysis, bukan face/medicine.
enum VotReviewOrigin { none, drinking }

/// Transisi UI setelah hasil backend, tanpa membuat ID sendiri.
class VotFlow {
  const VotFlow._();

  static const int maxAttempts = 3;

  static const String faceMaxAttemptMessage =
      'Verifikasi wajah belum berhasil setelah 3 percobaan.';

  static const String medicineMaxAttemptMessage =
      'Objek obat belum dapat diverifikasi. Silakan mulai ulang proses.';

  static bool reachedMaxAttempts(int localAttempts) {
    return localAttempts >= maxAttempts;
  }

  /// `needs_review` backend hanya dihormati setelah tahap minum/video.
  static bool isVideoNeedsReview({
    required String status,
    required String votStep,
  }) {
    if (status.toLowerCase() != 'needs_review') return false;
    return switch (votStep.toLowerCase()) {
      'medicine_matched' || 'drinking' || 'completed' => true,
      _ => false,
    };
  }

  /// Jadwal sudah tidak boleh dimulai pasien: verified ATAU needs_review video.
  ///
  /// Face/medicine gagal (termasuk `status=needs_review` di tahap wajah)
  /// bukan dosis selesai.
  static bool isDoseFinishedForPatient({
    required String status,
    required String votStep,
  }) {
    if (isServerVerified(status: status, votStep: votStep)) return true;
    return isVideoNeedsReview(status: status, votStep: votStep);
  }

  /// Gagal wajah/obat: sesi boleh dimulai ulang, jangan disembunyikan dari today.
  static bool isIncompleteVotSession({
    required String status,
    required String votStep,
  }) {
    if (isDoseFinishedForPatient(status: status, votStep: votStep)) {
      return false;
    }
    final String normalized = status.toLowerCase();
    return normalized == 'needs_review' ||
        normalized == 'in_progress' ||
        normalized == 'failed' ||
        normalized == 'cancelled';
  }

  static VerificationState afterStart({required String votStep, String? status}) {
    if (isVideoNeedsReview(status: status ?? '', votStep: votStep)) {
      return VerificationState.needsReview;
    }
    return switch (votStep) {
      'face_verified' => VerificationState.medicineDetecting,
      'medicine_matched' || 'drinking' => VerificationState.medicineMatched,
      'verified' => VerificationState.completed,
      _ => VerificationState.faceVerifying,
    };
  }

  static VotReviewOrigin reviewOriginFromVotStep(String votStep) {
    if (isVideoNeedsReview(status: 'needs_review', votStep: votStep)) {
      return VotReviewOrigin.drinking;
    }
    return VotReviewOrigin.none;
  }

  static int reviewActiveStepCount(VotReviewOrigin origin) {
    return origin == VotReviewOrigin.drinking ? 3 : 1;
  }

  static VerificationState afterFaceVerify({
    required bool verified,
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    if (verified) return VerificationState.faceVerified;
    return VerificationState.faceVerifying;
  }

  static VerificationState afterMedicineDetect({
    required bool medicineMatch,
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    if (medicineMatch) return VerificationState.medicineMatched;
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
    double? aiConfidence,
    Map<String, dynamic>? aiDetails,
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
    if (aiConfidence != null) {
      body['ai_confidence'] = aiConfidence;
    }
    if (aiDetails != null && aiDetails.isNotEmpty) {
      body['ai_details'] = aiDetails;
    }
    return body;
  }

  static VerificationState afterComplete({
    required bool serverVerified,
    bool isNeedsReview = false,
    bool canRetry = false,
  }) {
    if (serverVerified) return VerificationState.completed;
    return VerificationState.needsReview;
  }

  /// Timeout/gagal minum: needsReview khusus jalur video.
  static VerificationState afterDrinkingTimeout({
    bool canRetry = true,
    bool isNeedsReview = false,
  }) {
    return VerificationState.needsReview;
  }

  static VerificationState afterDrinkingRetry() {
    return VerificationState.drinking;
  }

  /// Langkah yang boleh diulang dari state error saat ini.
  static VotRetryTarget? retryTarget({
    required VerificationState state,
    required bool phaseError,
    bool maxAttemptsReached = false,
  }) {
    if (!phaseError || maxAttemptsReached) return null;
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
