import '../models/notification_model.dart';

/// Tujuan navigasi setelah tap notifikasi.
///
/// Tidak membuat route baru. `medicine` membuka HomePage existing, bukan AI-VOT.
enum NotificationOpenTarget {
  none,
  home,
  controlSchedule,
  complaintHistory,
  refillHistory,
  votSession,
}

/// Pemetaan tap notifikasi ke halaman existing.
///
/// `reference_id` dipakai apa adanya dari backend. Tidak dibuat ID palsu.
/// Tap `medicine` tidak memanggil `GET /vot/{id}` atau `POST /vot/start`.
/// Tap `video` tidak pernah memulai sesi VOT baru (`POST /vot/start`).
class NotificationTap {
  const NotificationTap._();

  static NotificationOpenTarget targetOf(NotificationModel item) {
    final String type = item.type.trim().toLowerCase();
    if (type == 'control' || item.isControlScheduleNotification) {
      return NotificationOpenTarget.controlSchedule;
    }
    if (type == 'complaint') {
      return NotificationOpenTarget.complaintHistory;
    }
    if (type == 'video') {
      return NotificationOpenTarget.votSession;
    }
    if (type == 'refill') {
      return NotificationOpenTarget.refillHistory;
    }
    if (type == 'medicine' || item.isMedicineNotification) {
      return NotificationOpenTarget.home;
    }
    return NotificationOpenTarget.none;
  }

  static int? _positiveId(int? value) {
    if (value == null || value <= 0) return null;
    return value;
  }

  /// `reference_id` sebagai `complaint_id`. Null bila tidak ada.
  static int? complaintId(NotificationModel item) {
    if (targetOf(item) != NotificationOpenTarget.complaintHistory) {
      return null;
    }
    return _positiveId(item.referenceId);
  }

  /// `reference_id` sebagai `daily_medication_id`. Null bila tidak ada.
  static int? dailyMedicationId(NotificationModel item) {
    if (targetOf(item) != NotificationOpenTarget.votSession) {
      return null;
    }
    return _positiveId(item.referenceId);
  }

  /// `reference_id` sebagai `refill_id` untuk highlight riwayat. Opsional.
  static int? refillId(NotificationModel item) {
    if (targetOf(item) != NotificationOpenTarget.refillHistory) {
      return null;
    }
    return _positiveId(item.referenceId);
  }

  /// Tap video tidak boleh memanggil `POST /vot/start`.
  ///
  /// Navigasi memakai `GET /vot/{daily_medication_id}` pada halaman AI-VOT
  /// existing. Parameter [item] dipakai agar pemanggil selalu menautkan
  /// keputusan ini ke notifikasi yang ditekan.
  static bool startsNewVotSession(NotificationModel item) {
    if (item.isVideoNotification) return false;
    return false;
  }

  static bool shouldNavigate(NotificationModel item) {
    switch (targetOf(item)) {
      case NotificationOpenTarget.none:
        return false;
      case NotificationOpenTarget.votSession:
        return dailyMedicationId(item) != null;
      case NotificationOpenTarget.home:
      case NotificationOpenTarget.controlSchedule:
      case NotificationOpenTarget.complaintHistory:
      case NotificationOpenTarget.refillHistory:
        return true;
    }
  }

  /// `medicine` tidak membuka sesi VOT, meski `reference_id` ada.
  static bool opensVot(NotificationModel item) {
    return targetOf(item) == NotificationOpenTarget.votSession &&
        dailyMedicationId(item) != null;
  }
}
