/// Response `POST /vot/face-verify`.
class VotFaceVerifyResult {
  const VotFaceVerifyResult({
    required this.dailyMedicationId,
    required this.medicineScheduleId,
    required this.faceVerificationId,
    required this.verified,
    required this.similarityScore,
    required this.threshold,
    required this.status,
    required this.votStep,
    required this.message,
    this.attemptCount = 0,
    this.canRetry = true,
    this.failureReason,
  });

  final int dailyMedicationId;
  final int medicineScheduleId;
  final int faceVerificationId;
  final bool verified;
  final double similarityScore;
  final double threshold;
  final String status;
  final String votStep;
  final String message;
  final int attemptCount;
  final bool canRetry;
  final String? failureReason;

  factory VotFaceVerifyResult.fromJson(Map<String, dynamic> json) {
    return VotFaceVerifyResult(
      dailyMedicationId: (json['daily_medication_id'] as num?)?.toInt() ?? 0,
      medicineScheduleId:
          (json['medicine_schedule_id'] as num?)?.toInt() ?? 0,
      faceVerificationId:
          (json['face_verification_id'] as num?)?.toInt() ?? 0,
      verified: json['verified'] as bool? ?? false,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      message: json['message']?.toString().trim() ?? '',
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      canRetry: json['can_retry'] as bool? ?? true,
      failureReason: json['failure_reason']?.toString().trim(),
    );
  }
}
