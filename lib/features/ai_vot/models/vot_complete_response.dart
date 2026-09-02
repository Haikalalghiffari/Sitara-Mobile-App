/// Response `POST /vot/complete`.
class VotCompleteResponse {
  const VotCompleteResponse({
    required this.dailyMedicationId,
    required this.status,
    required this.votStep,
    required this.completedAt,
    required this.message,
    this.attemptCount = 0,
    this.canRetry = false,
    this.failureReason,
    this.maxDrinkingStage,
  });

  final int dailyMedicationId;
  final String status;
  final String votStep;
  final String? completedAt;
  final String message;
  final int attemptCount;
  final bool canRetry;
  final String? failureReason;
  final String? maxDrinkingStage;

  bool get isFinalSuccess => status.toLowerCase() == 'verified' && votStep.toLowerCase() == 'verified';
  bool get isNeedsReview => status.toLowerCase() == 'needs_review';

  factory VotCompleteResponse.fromJson(Map<String, dynamic> json) {
    return VotCompleteResponse(
      dailyMedicationId: (json['daily_medication_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
      message: json['message']?.toString().trim() ?? '',
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
      canRetry: json['can_retry'] as bool? ?? false,
      failureReason: json['failure_reason']?.toString().trim(),
      maxDrinkingStage: json['max_drinking_stage']?.toString().trim(),
    );
  }
}
