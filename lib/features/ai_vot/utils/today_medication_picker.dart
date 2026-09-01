import '../models/daily_medication.dart';

/// Ketersediaan jadwal AI-VOT dari `GET /medications/today`.
enum VotScheduleKind {
  empty,
  upcoming,
  finished,
  eligible,
}

/// Hasil evaluasi jadwal hari ini, termasuk pesan informasi (bukan error).
class VotScheduleSnapshot {
  const VotScheduleSnapshot({
    required this.kind,
    required this.message,
    this.selected,
    this.nextUpcoming,
  });

  final VotScheduleKind kind;
  final String message;
  final DailyMedication? selected;
  final DailyMedication? nextUpcoming;

  bool get isEligible => kind == VotScheduleKind.eligible;
}

/// Memilih DailyMedication dari seluruh list `GET /medications/today`.
///
/// Source of truth eligibility: field `eligible` dari backend (timezone
/// Asia/Jakarta). Flutter tidak menimpa dengan `now >= scheduled_time`.
///
/// Prioritas:
/// 1. `in_progress` → resume
/// 2. `eligible == true` dan belum verified
/// 3. upcoming (`eligible == false`, belum verified) → informasi saja
/// 4. semua verified → selesai
class TodayMedicationPicker {
  const TodayMedicationPicker._();

  /// Refresh `GET /medications/today` saat upcoming, bukan override lokal.
  static const Duration watchInterval = Duration(seconds: 45);

  static DailyMedication? pick(List<DailyMedication> items) {
    return inspect(items).selected;
  }

  static VotScheduleSnapshot inspect(List<DailyMedication> items) {
    if (items.isEmpty) {
      return const VotScheduleSnapshot(
        kind: VotScheduleKind.empty,
        message: 'Hari ini tidak ada jadwal minum obat.',
      );
    }

    final List<DailyMedication> ordered = List<DailyMedication>.of(items)
      ..sort(_byScheduledTime);

    final List<DailyMedication> inProgress = ordered
        .where((DailyMedication item) => item.isInProgress)
        .toList();
    if (inProgress.isNotEmpty) {
      return VotScheduleSnapshot(
        kind: VotScheduleKind.eligible,
        message: 'Melanjutkan verifikasi minum obat...',
        selected: inProgress.first,
      );
    }

    final List<DailyMedication> eligible = ordered
        .where(_isBackendEligible)
        .toList();
    if (eligible.isNotEmpty) {
      return VotScheduleSnapshot(
        kind: VotScheduleKind.eligible,
        message: 'Jadwal minum obat tersedia.',
        selected: eligible.first,
      );
    }

    final DailyMedication? upcoming = nextUpcoming(ordered);
    if (upcoming != null) {
      final String label = upcoming.scheduledTimeLabel ?? upcoming.scheduledTime;
      return VotScheduleSnapshot(
        kind: VotScheduleKind.upcoming,
        message: 'Jadwal minum obat berikutnya pukul $label.',
        nextUpcoming: upcoming,
      );
    }

    return const VotScheduleSnapshot(
      kind: VotScheduleKind.finished,
      message: 'Semua jadwal minum obat hari ini sudah selesai.',
    );
  }

  /// Item `eligible == true` yang belum verified. Null tidak dianggap true.
  static bool _isBackendEligible(DailyMedication item) {
    if (item.isServerVerified) return false;
    return item.eligible == true;
  }

  /// Upcoming: belum verified, `eligible == false`.
  static DailyMedication? nextUpcoming(List<DailyMedication> items) {
    final List<DailyMedication> upcoming = items
        .where((DailyMedication item) {
          if (item.isServerVerified) return false;
          if (item.isInProgress) return false;
          if (item.eligible == false) return true;
          return item.eligible == null && item.isPending;
        })
        .toList()
      ..sort(_byScheduledTime);
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  /// Jadwal yang ditampilkan di home: current eligible/in_progress, atau
  /// upcoming hari ini. Tidak membuat jadwal besok.
  static DailyMedication? homeNext(List<DailyMedication> items) {
    final VotScheduleSnapshot snapshot = inspect(items);
    return snapshot.selected ?? snapshot.nextUpcoming;
  }

  static String allFinishedMessage() =>
      'Semua jadwal minum obat hari ini sudah selesai.';

  static String thisScheduleFinishedMessage() =>
      'Verifikasi minum obat untuk jadwal ini sudah selesai.';

  static int _byScheduledTime(DailyMedication a, DailyMedication b) {
    final int left = a.scheduledMinutesOfDay ?? 1 << 20;
    final int right = b.scheduledMinutesOfDay ?? 1 << 20;
    return left.compareTo(right);
  }
}
