import '../models/notification_model.dart';

/// Filter pill halaman notifikasi pasien.
///
/// Sumber kebenaran: field `type` dari `NotificationType` backend
/// (`medicine`, `control`, `complaint`, `refill`, `video`).
/// Tidak memakai title/message.
enum NotificationCategoryFilter {
  all('Semua'),
  medicine('Obat'),
  control('Kontrol'),
  complaint('Keluhan');

  const NotificationCategoryFilter(this.label);

  final String label;

  static List<String> get labels =>
      NotificationCategoryFilter.values.map((e) => e.label).toList();

  static NotificationCategoryFilter? fromLabel(String label) {
    for (final NotificationCategoryFilter value
        in NotificationCategoryFilter.values) {
      if (value.label == label) return value;
    }
    return null;
  }

  bool matches(NotificationModel item) {
    final String type = item.type.trim().toLowerCase();
    return switch (this) {
      NotificationCategoryFilter.all => true,
      NotificationCategoryFilter.medicine =>
        type == 'medicine' || type == 'refill',
      NotificationCategoryFilter.control => type == 'control',
      NotificationCategoryFilter.complaint => type == 'complaint',
    };
  }
}
