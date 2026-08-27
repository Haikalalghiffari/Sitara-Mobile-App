/// Satu baris dari `GET /medications/today` / `GET /vot/{id}`.
class DailyMedication {
  const DailyMedication({
    required this.dailyMedicationId,
    required this.medicineScheduleId,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.quantityRemaining,
    required this.status,
    required this.votStep,
    this.eligible,
  });

  final int dailyMedicationId;
  final int medicineScheduleId;
  final int medicineId;
  final String medicineName;
  final String dosage;
  final String scheduledDate;
  final String scheduledTime;
  final int quantityRemaining;
  final String status;
  final String votStep;

  /// `eligible` dari `GET /medications/today`. Null pada `GET /vot/{id}`
  /// karena schema sesi tidak mengirim field ini.
  final bool? eligible;

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';

  /// Boleh mulai atau lanjut hanya jika backend mengizinkan.
  ///
  /// `eligible == true` adalah source of truth dari `GET /medications/today`.
  /// Null tidak dianggap true.
  bool get canStartOrResume {
    if (isServerVerified) return false;
    if (isInProgress) return true;
    return eligible == true;
  }

  bool get isFaceVerified => votStep == 'face_verified';
  bool get isMedicineMatched =>
      votStep == 'medicine_matched' || votStep == 'drinking';
  bool get isServerVerified => votStep == 'verified' || status == 'verified';

  /// `HH:mm` dari `scheduled_time`, untuk teks informasi jadwal.
  String? get scheduledTimeLabel {
    final int? minutes = scheduledMinutesOfDay;
    if (minutes == null) return null;
    final String hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final String minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Waktu minum hari [day] di zona perangkat, dari `scheduled_time`.
  DateTime? scheduledDateTimeOn(DateTime day) {
    final List<String> parts = scheduledTime.split(':');
    if (parts.length < 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final int second = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute, second);
  }

  int? get scheduledMinutesOfDay {
    final List<String> parts = scheduledTime.split(':');
    if (parts.length < 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  factory DailyMedication.fromJson(Map<String, dynamic> json) {
    final int dailyId = (json['daily_medication_id'] as num?)?.toInt() ?? 0;
    final int scheduleId =
        (json['medicine_schedule_id'] as num?)?.toInt() ?? 0;
    if (dailyId <= 0 || scheduleId <= 0) {
      throw const FormatException(
        'daily_medication_id atau medicine_schedule_id tidak valid.',
      );
    }

    return DailyMedication(
      dailyMedicationId: dailyId,
      medicineScheduleId: scheduleId,
      medicineId: (json['medicine_id'] as num?)?.toInt() ?? 0,
      medicineName: json['medicine_name']?.toString().trim() ?? '',
      dosage: json['dosage']?.toString().trim() ?? '',
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? '',
      quantityRemaining: (json['quantity_remaining'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      votStep: json['vot_step']?.toString() ?? '',
      eligible: _parseEligible(json['eligible']),
    );
  }

  /// Bool nullable-safe. Tidak default `true` jika field absen.
  static bool? _parseEligible(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    return null;
  }
}
