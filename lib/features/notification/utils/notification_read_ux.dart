import '../models/notification_model.dart';

/// Update daftar notifikasi setelah mark-read, tanpa persistence palsu.
class NotificationReadUx {
  const NotificationReadUx._();

  static int unreadCount(List<NotificationModel> items) {
    return items.where((NotificationModel item) => !item.isRead).length;
  }

  static List<NotificationModel> applyRead(
    List<NotificationModel> items,
    NotificationModel updated,
  ) {
    if (!updated.isRead) return items;
    return items
        .map(
          (NotificationModel current) =>
              current.id == updated.id ? updated : current,
        )
        .toList();
  }

  /// Refresh gagal: data lama tetap dipakai bila sudah ada.
  static bool keepExistingOnError({
    required bool silent,
    required List<NotificationModel> existing,
  }) {
    return silent && existing.isNotEmpty;
  }

  /// Gerbang request ganda. Spinner UI tidak boleh dipakai: frame pertama
  /// sudah `loading = true`, tetapi HTTP belum jalan.
  static bool skipDuplicateFetch({required bool inFlight}) => inFlight;
}

/// Satu permintaan mark-read per id, agar tap beruntun tidak menduplikasi API.
class NotificationReadLock {
  final Set<int> _inFlight = <int>{};

  bool get isBusy => _inFlight.isNotEmpty;

  bool isMarking(int id) => _inFlight.contains(id);

  bool tryBegin(int id) {
    if (_inFlight.contains(id)) return false;
    _inFlight.add(id);
    return true;
  }

  void end(int id) {
    _inFlight.remove(id);
  }
}
