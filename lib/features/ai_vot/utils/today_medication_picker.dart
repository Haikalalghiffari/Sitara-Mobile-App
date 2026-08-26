import '../models/daily_medication.dart';

/// Memilih DailyMedication yang akan diverifikasi.
///
/// Backend `GET /medications/today` sudah diurutkan `drink_time` naik.
/// Item `verified` / `missed` / `rejected` tidak dapat di-start ulang.
///
/// Urutan:
/// 1. Sesi `in_progress` (lanjutkan), waktu jadwal paling awal
/// 2. `pending` berikutnya berdasarkan `scheduled_time` vs waktu sekarang
/// 3. Jika semua jam pending sudah lewat, ambil pending paling awal
class TodayMedicationPicker {
  const TodayMedicationPicker._();

  static DailyMedication? pick(
    List<DailyMedication> items, {
    DateTime? now,
  }) {
    final List<DailyMedication> eligible = items
        .where((DailyMedication item) => item.canStartOrResume)
        .toList();
    if (eligible.isEmpty) return null;

    final List<DailyMedication> inProgress = eligible
        .where((DailyMedication item) => item.isInProgress)
        .toList()
      ..sort(_byScheduledTime);

    if (inProgress.isNotEmpty) return inProgress.first;

    final List<DailyMedication> pending = eligible
        .where((DailyMedication item) => item.isPending)
        .toList()
      ..sort(_byScheduledTime);

    if (pending.isEmpty) return null;

    final DateTime clock = now ?? DateTime.now();
    final int currentMinutes = clock.hour * 60 + clock.minute;

    for (final DailyMedication item in pending) {
      final int? minutes = item.scheduledMinutesOfDay;
      if (minutes != null && minutes >= currentMinutes) {
        return item;
      }
    }

    return pending.first;
  }

  static int _byScheduledTime(DailyMedication a, DailyMedication b) {
    final int left = a.scheduledMinutesOfDay ?? 1 << 20;
    final int right = b.scheduledMinutesOfDay ?? 1 << 20;
    return left.compareTo(right);
  }
}
