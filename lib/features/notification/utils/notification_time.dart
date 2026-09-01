import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

/// Parse `created_at` dan label waktu relatif, tanpa polling API.
///
/// Convention backend: `Notification.created_at` disimpan UTC. String tanpa
/// zona (`Z` / offset) dianggap UTC, lalu diubah ke local sekali.
class NotificationTime {
  const NotificationTime._();

  /// Offset/`Z` → UTC lalu local sekali. Naive → UTC lalu local sekali.
  static DateTime? parse(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    final DateTime utc = parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
    final DateTime local = utc.toLocal();

    if (kDebugMode) {
      debugPrint('[NotificationTime] raw = $value');
      debugPrint('[NotificationTime] parsedUtc = $utc');
      debugPrint('[NotificationTime] local = $local');
      debugPrint('[NotificationTime] now = ${DateTime.now()}');
      debugPrint(
        '[NotificationTime] difference = ${DateTime.now().difference(local)}',
      );
    }

    return local;
  }

  static String relative(
    DateTime? created, {
    DateTime? now,
  }) {
    if (created == null) return '';
    final DateTime clock = now ?? DateTime.now();
    final Duration elapsed = clock.difference(created);
    if (elapsed.isNegative) return 'baru saja';
    if (elapsed.inMinutes < 1) return 'baru saja';
    if (elapsed.inMinutes == 1) return '1 menit yang lalu';
    if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes} menit yang lalu';
    }
    if (elapsed.inHours == 1) return '1 jam yang lalu';
    if (elapsed.inHours < 24) return '${elapsed.inHours} jam yang lalu';
    if (elapsed.inDays == 1) return '1 hari yang lalu';
    return '${elapsed.inDays} hari yang lalu';
  }

  static String labelFor(
    NotificationModel item, {
    DateTime? now,
  }) {
    return relative(item.createdAtDateTime, now: now);
  }
}
