import '../../../core/utils/indonesian_date.dart';

/// `pickup_facility` pada `RefillResponse`, berasal dari `HealthFacility`
/// milik fasilitas akun pasien.
///
/// Backend menyatakan `address`, `phone`, `latitude`, dan `longitude` boleh
/// null, jadi keempatnya tidak dipaksa non-null di sini. Backend tidak
/// mengirim tanggal maupun jam pengambilan, sehingga model ini juga tidak
/// memilikinya.
class PickupFacility {
  const PickupFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  factory PickupFacility.fromJson(Map<String, dynamic> json) {
    return PickupFacility(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      latitude: _coordinate(json['latitude']),
      longitude: _coordinate(json['longitude']),
    );
  }

  /// `pickup_facility` bisa absen atau null pada permintaan yang belum
  /// disetujui, jadi nilai yang bukan objek menghasilkan null.
  static PickupFacility? maybeFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return PickupFacility.fromJson(data);
    }
    return null;
  }

  /// Backend dapat mengirim koordinat sebagai angka atau teks desimal.
  /// Nilai yang tidak terbaca menghasilkan null, bukan 0.
  static double? _coordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Nama fasilitas yang layak ditampilkan, null bila kosong.
  String? get nameText {
    final String text = name.trim();
    if (text.isEmpty) return null;
    return text;
  }

  /// Alamat yang layak ditampilkan, null bila backend mengirim null/kosong.
  String? get addressText {
    final String? text = address?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  /// Nomor telepon yang layak ditampilkan, null bila kosong.
  String? get phoneText {
    final String? text = phone?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  /// URL pencarian Google Maps dari koordinat backend.
  ///
  /// Backend tidak mengirim URL maps, jadi tautannya dibangun di sisi aplikasi.
  /// Null bila salah satu koordinat tidak tersedia, agar tidak ada lokasi
  /// karangan yang dibuka.
  Uri? get mapsUri {
    final double? lat = latitude;
    final double? lng = longitude;
    if (lat == null || lng == null) return null;

    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': '$lat,$lng',
    });
  }

  @override
  String toString() => 'PickupFacility(id: $id, name: $name)';
}

/// Response `RefillResponse` dari `GET /refills/my` dan `POST /refills`.
///
/// Field mengikuti persis schema backend, tanpa tambahan. Nama obat tidak ada
/// pada response ini; yang dikirim hanya `medicine_id`.
class Refill {
  const Refill({
    required this.id,
    required this.treatmentId,
    required this.medicineId,
    required this.quantity,
    required this.reason,
    required this.description,
    required this.status,
    required this.nurseNote,
    required this.approvedBy,
    required this.approvedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.pickupFacility,
  });

  final int id;
  final int treatmentId;
  final int medicineId;
  final int quantity;

  /// Backend menyimpannya sebagai teks bebas, bukan enum.
  final String reason;

  /// Keterangan tambahan dari pasien, boleh null.
  final String? description;

  /// `RefillRequestStatus`: `pending`, `approved`, atau `rejected`.
  final String status;

  /// Catatan dari nakes, boleh null selama permintaan belum ditinjau.
  final String? nurseNote;

  /// Id nakes yang menyetujui, null selama belum disetujui.
  final int? approvedBy;

  final String? approvedAt;

  final bool isActive;
  final String createdAt;
  final String updatedAt;

  /// `pickup_facility` dari backend. Null bila tidak dikirim.
  final PickupFacility? pickupFacility;

  /// Body `POST /refills` (`RefillCreate`).
  ///
  /// `description` opsional di backend, jadi hanya dikirim jika terisi.
  static Map<String, dynamic> createRequestBody({
    required int treatmentId,
    required int medicineId,
    required int quantity,
    required String reason,
    String? description,
  }) {
    final Map<String, dynamic> body = <String, dynamic>{
      'treatment_id': treatmentId,
      'medicine_id': medicineId,
      'quantity': quantity,
      'reason': reason,
    };

    final String? detail = description?.trim();
    if (detail != null && detail.isNotEmpty) {
      body['description'] = detail;
    }
    return body;
  }

  factory Refill.fromJson(Map<String, dynamic> json) {
    return Refill(
      id: (json['id'] as num?)?.toInt() ?? 0,
      treatmentId: (json['treatment_id'] as num?)?.toInt() ?? 0,
      medicineId: (json['medicine_id'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? '',
      nurseNote: json['nurse_note']?.toString(),
      approvedBy: (json['approved_by'] as num?)?.toInt(),
      approvedAt: json['approved_at']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      pickupFacility: PickupFacility.maybeFromJson(json['pickup_facility']),
    );
  }

  /// Label status berbahasa Indonesia.
  ///
  /// Hanya tiga status milik `RefillRequestStatus` yang dikenali. Nilai di luar
  /// itu menghasilkan null agar UI tidak menampilkan status karangan.
  String? get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return null;
    }
  }

  /// `RefillRequestStatus.APPROVED` dari backend.
  bool get isApproved => status.trim().toLowerCase() == 'approved';

  /// Fasilitas pengambilan yang layak ditampilkan.
  ///
  /// Hanya untuk permintaan yang sudah disetujui, dan hanya bila backend
  /// benar-benar mengirim `pickup_facility` beserta namanya. Tidak ada
  /// fasilitas karangan ketika datanya belum ada.
  PickupFacility? get approvedPickupFacility {
    if (!isApproved) return null;
    final PickupFacility? facility = pickupFacility;
    if (facility == null || facility.nameText == null) return null;
    return facility;
  }

  /// Tanggal permintaan dibuat, tanpa konversi zona waktu.
  DateTime? get createdAtDateTime => DateTime.tryParse(createdAt);

  /// `13 Agustus 2026`, null bila `created_at` tidak dapat dibaca.
  String? get createdAtLabel => formatIndonesianDate(createdAtDateTime);

  /// Keterangan pasien yang layak ditampilkan, null bila kosong.
  String? get descriptionText {
    final String? text = description?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  /// Catatan nakes yang layak ditampilkan, null bila kosong.
  String? get nurseNoteText {
    final String? text = nurseNote?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  /// Daftar permintaan dari yang terbaru.
  ///
  /// Urutan dari backend tidak dijamin, jadi diurutkan berdasarkan
  /// `created_at`. Permintaan yang tanggalnya tidak terbaca ditempatkan di
  /// akhir tanpa dibuang, karena datanya tetap milik pasien.
  static List<Refill> sortedByNewest(List<Refill> refills) {
    final List<Refill> sorted = List<Refill>.from(refills);

    sorted.sort((Refill a, Refill b) {
      final DateTime? aCreated = a.createdAtDateTime;
      final DateTime? bCreated = b.createdAtDateTime;
      if (aCreated == null && bCreated == null) return 0;
      if (aCreated == null) return 1;
      if (bCreated == null) return -1;
      return bCreated.compareTo(aCreated);
    });

    return sorted;
  }

  /// Mencari permintaan dari hasil `GET /refills/my`. Null bila tidak ada.
  static Refill? findById(List<Refill> items, int? id) {
    if (id == null || id <= 0) return null;
    for (final Refill item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Permintaan terbaru, dipakai kartu informasi untuk menampilkan statusnya.
  static Refill? selectLatest(List<Refill> refills) {
    if (refills.isEmpty) return null;
    return sortedByNewest(refills).first;
  }

  @override
  String toString() =>
      'Refill(id: $id, medicineId: $medicineId, quantity: $quantity, '
      'status: $status)';
}
