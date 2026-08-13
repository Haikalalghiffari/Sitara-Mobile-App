/// Response `ControlScheduleResponse` dari `GET /control-schedules/my`.
///
/// Field mengikuti persis schema backend, tanpa tambahan.
///
/// `controlDate` dan `controlTime` disimpan sebagai [String] apa adanya.
/// Parsing hanya dilakukan lewat getter supaya format yang tidak terduga tidak
/// menggagalkan seluruh pemuatan daftar.
class ControlSchedule {
  const ControlSchedule({
    required this.id,
    required this.treatmentId,
    required this.controlDate,
    required this.controlTime,
    required this.status,
    required this.doctorNote,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int treatmentId;

  /// Tipe backend: `date`, misalnya `2026-08-21`.
  final String controlDate;

  /// Tipe backend: `time`, misalnya `09:00:00`, tanpa zona waktu.
  final String controlTime;

  /// `ControlScheduleStatus`: `pending`, `completed`, `missed`, `cancelled`.
  final String status;

  /// Boleh null di backend (`String(500)`, `nullable=True`).
  final String? doctorNote;

  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory ControlSchedule.fromJson(Map<String, dynamic> json) {
    return ControlSchedule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      treatmentId: (json['treatment_id'] as num?)?.toInt() ?? 0,
      controlDate: json['control_date']?.toString() ?? '',
      controlTime: json['control_time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      doctorNote: json['doctor_note']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static const List<String> _monthNames = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Tanggal kontrol tanpa komponen jam.
  DateTime? get date {
    final DateTime? parsed = DateTime.tryParse(controlDate);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Menit sejak tengah malam dari `control_time`.
  int? get _minutesOfDay {
    final List<String> parts = controlTime.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return hour * 60 + minute;
  }

  /// Tanggal dan jam kontrol sebagai satu waktu lokal.
  ///
  /// `control_time` dipasang apa adanya tanpa konversi UTC. Bila jam tidak
  /// terbaca, tanggalnya tetap dipakai pada pukul 00.00.
  DateTime? get scheduledAt {
    final DateTime? day = date;
    if (day == null) return null;

    final int? minutes = _minutesOfDay;
    if (minutes == null) return day;

    return DateTime(
      day.year,
      day.month,
      day.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  /// `21 Agustus 2026`, null bila `control_date` tidak dapat dibaca.
  String? get dateLabel {
    final DateTime? day = date;
    if (day == null) return null;

    return '${day.day} ${_monthNames[day.month - 1]} ${day.year}';
  }

  /// `09.00` dari `09:00:00`.
  ///
  /// Detik dibuang dan label zona waktu tidak ditambahkan karena backend
  /// mengirim jam polos tanpa informasi zona.
  String? get timeLabel {
    final int? minutes = _minutesOfDay;
    if (minutes == null) return null;

    final String hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final String minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Label status berbahasa Indonesia.
  ///
  /// Hanya empat status milik `ControlScheduleStatus` yang dikenali. Nilai di
  /// luar itu menghasilkan null agar UI tidak menampilkan status karangan.
  String? get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'completed':
        return 'Selesai';
      case 'missed':
        return 'Terlewat';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return null;
    }
  }

  /// Catatan dokter yang layak ditampilkan, null bila kosong.
  String? get doctorNoteText {
    final String? note = doctorNote?.trim();
    if (note == null || note.isEmpty) return null;
    return note;
  }

  /// Jadwal kontrol yang ditampilkan di kartu "Jadwal Kontrol Berikutnya".
  ///
  /// Yang dipilih adalah jadwal terdekat yang belum lewat. Bila semuanya sudah
  /// lewat, jadwal terakhir dipakai supaya statusnya (Selesai/Terlewat) tetap
  /// terlihat, ketimbang menyembunyikan data yang memang ada.
  static ControlSchedule? selectUpcoming(
    List<ControlSchedule> schedules, {
    DateTime? now,
  }) {
    final List<ControlSchedule> dated = schedules
        .where((ControlSchedule item) => item.scheduledAt != null)
        .toList();

    if (dated.isEmpty) return null;

    dated.sort((ControlSchedule a, ControlSchedule b) {
      return a.scheduledAt!.compareTo(b.scheduledAt!);
    });

    final DateTime reference = now ?? DateTime.now();

    for (final ControlSchedule item in dated) {
      if (!item.scheduledAt!.isBefore(reference)) return item;
    }

    return dated.last;
  }

  @override
  String toString() =>
      'ControlSchedule(id: $id, controlDate: $controlDate, status: $status)';
}
