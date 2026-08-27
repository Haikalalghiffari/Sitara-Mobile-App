/// Response `NotificationResponse` dari backend SITARA.
///
/// Field mengikuti persis apa yang dikirim backend, tanpa tambahan.
///
/// `createdAt` dan `updatedAt` disimpan sebagai [String] apa adanya. Parsing ke
/// [DateTime] baru dilakukan di lapisan tampilan lewat [createdAtDateTime],
/// supaya format yang tidak terduga tidak menggagalkan seluruh pemuatan daftar.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.referenceType,
    required this.referenceId,
    required this.isRead,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int userId;
  final String title;
  final String message;

  /// Salah satu nilai `NotificationType` backend: `medicine`, `control`,
  /// `complaint`, `refill`, atau `video`.
  final String type;

  /// `NotificationReferenceType` backend, boleh null sesuai schema.
  final String? referenceType;

  final int? referenceId;

  final bool isRead;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      referenceType: json['reference_type']?.toString(),
      referenceId: (json['reference_id'] as num?)?.toInt(),
      isRead: json['is_read'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  String get normalizedType => type.trim().toLowerCase();

  /// Notifikasi jadwal kontrol dari backend.
  ///
  /// `NotificationType.CONTROL` bernilai `control`;
  /// `NotificationReferenceType.CONTROL_SCHEDULE` bernilai `control_schedule`.
  /// Perbandingan tidak peka huruf besar/kecil karena serializer enum bisa
  /// mengirim nama atau nilai.
  bool get isControlScheduleNotification {
    if (normalizedType == 'control') return true;
    return referenceType?.toLowerCase() == 'control_schedule';
  }

  bool get isMedicineNotification => normalizedType == 'medicine';

  bool get isComplaintNotification => normalizedType == 'complaint';

  bool get isVideoNotification => normalizedType == 'video';

  bool get isRefillNotification => normalizedType == 'refill';

  /// Waktu pembuatan dalam zona waktu perangkat.
  ///
  /// Backend mengirim tipe `date-time`. Bila nilainya menyertakan penanda UTC,
  /// hasilnya dikonversi ke waktu lokal; bila tidak, nilai dipakai apa adanya
  /// tanpa mengasumsikan zona waktu tertentu.
  DateTime? get createdAtDateTime {
    final DateTime? parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  @override
  String toString() =>
      'NotificationModel(id: $id, userId: $userId, type: $type, '
      'isRead: $isRead)';
}
