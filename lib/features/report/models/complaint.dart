import '../../../core/utils/indonesian_date.dart';

/// Response `ComplaintResponse` dari `GET /complaints/my` dan `POST
/// /complaints`.
///
/// Field mengikuti persis schema backend, tanpa tambahan.
class Complaint {
  const Complaint({
    required this.id,
    required this.treatmentId,
    required this.handledBy,
    required this.category,
    required this.description,
    required this.status,
    required this.response,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int treatmentId;

  /// Id nakes yang menangani, null selama keluhan belum ditangani.
  final int? handledBy;

  /// Backend menyimpannya sebagai teks bebas, bukan enum.
  final String category;

  final String description;

  /// `ComplaintStatus`: `pending`, `in_progress`, atau `resolved`.
  final String status;

  /// Balasan dari nakes, boleh null.
  final String? response;

  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: (json['id'] as num?)?.toInt() ?? 0,
      treatmentId: (json['treatment_id'] as num?)?.toInt() ?? 0,
      handledBy: (json['handled_by'] as num?)?.toInt(),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      response: json['response']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  /// Label status berbahasa Indonesia.
  ///
  /// Hanya tiga status milik `ComplaintStatus` yang dikenali. Nilai di luar itu
  /// menghasilkan null agar UI tidak menampilkan status karangan.
  String? get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Sedang Ditangani';
      case 'resolved':
        return 'Selesai';
      default:
        return null;
    }
  }

  /// Tanggal keluhan dibuat, tanpa konversi zona waktu.
  DateTime? get createdAtDateTime => DateTime.tryParse(createdAt);

  /// `13 Agustus 2026`, null bila `created_at` tidak dapat dibaca.
  String? get createdAtLabel => formatIndonesianDate(createdAtDateTime);

  /// Balasan nakes yang layak ditampilkan, null bila kosong.
  String? get responseText {
    final String? text = response?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  String toString() =>
      'Complaint(id: $id, category: $category, status: $status)';
}
