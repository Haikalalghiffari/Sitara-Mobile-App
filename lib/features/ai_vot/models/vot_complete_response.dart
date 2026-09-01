/// Response `POST /vot/complete`.
class VotCompleteResponse {
  const VotCompleteResponse({
    required this.dailyMedicationId,
    required this.status,
    required this.votStep,
    required this.completedAt,
    required this.message,
  });

  final int dailyMedicationId;
  final String status;
  final String votStep;
  final String? completedAt;
  final String message;

  bool get isFinalSuccess => status == 'verified' && votStep == 'verified';

  factory VotCompleteResponse.fromJson(Map<String, dynamic> json) {
    return VotCompleteResponse(
      dailyMedicationId: (json['daily_medication_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
      message: json['message']?.toString().trim() ?? '',
    );
  }
}
