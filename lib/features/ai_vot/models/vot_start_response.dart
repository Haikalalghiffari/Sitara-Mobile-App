/// Response `POST /vot/start`.
class VotStartResponse {
  const VotStartResponse({
    required this.dailyMedicationId,
    required this.medicineScheduleId,
    required this.status,
    required this.votStep,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  final int dailyMedicationId;
  final int medicineScheduleId;
  final String status;
  final String votStep;
  final String scheduledDate;
  final String scheduledTime;

  factory VotStartResponse.fromJson(Map<String, dynamic> json) {
    final int dailyId = (json['daily_medication_id'] as num?)?.toInt() ?? 0;
    if (dailyId <= 0) {
      throw const FormatException('daily_medication_id tidak valid.');
    }

    return VotStartResponse(
      dailyMedicationId: dailyId,
      medicineScheduleId:
          (json['medicine_schedule_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? '',
    );
  }
}
