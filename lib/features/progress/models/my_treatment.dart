import '../../../core/utils/indonesian_date.dart';

/// Response `MyTreatmentResponse` dari `GET /treatments/my`.
///
/// Field mengikuti persis schema backend, tanpa tambahan.
///
/// `therapyStartDate` dan `therapyEndDate` disimpan sebagai [String] apa
/// adanya. Parsing ke [DateTime] hanya dilakukan lewat getter, supaya format
/// yang tidak terduga tidak menggagalkan seluruh pemuatan daftar.
class MyTreatment {
  const MyTreatment({
    required this.id,
    required this.patientId,
    required this.therapyStartDate,
    required this.therapyEndDate,
    required this.phase,
    required this.regimen,
    required this.status,
    required this.doctorName,
  });

  final int id;
  final int patientId;

  /// Tipe backend: `date`.
  final String therapyStartDate;

  /// Tipe backend: `date`.
  final String therapyEndDate;

  /// `TreatmentPhase`: `intensive` atau `continuation`.
  final String phase;

  /// `RegimenEnum`: `category_1`, `category_2`, atau `mdr`.
  final String regimen;

  /// `TreatmentStatus`: `active`, `completed`, atau `dropped`.
  final String status;

  final String doctorName;

  factory MyTreatment.fromJson(Map<String, dynamic> json) {
    return MyTreatment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      therapyStartDate: json['therapy_start_date']?.toString() ?? '',
      therapyEndDate: json['therapy_end_date']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      regimen: json['regimen']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  /// Label fase terapi berbahasa Indonesia.
  ///
  /// Hanya dua nilai milik `TreatmentPhase` yang dikenali. Nilai di luar itu
  /// menghasilkan null agar UI tidak menampilkan fase karangan.
  String? get phaseLabel {
    switch (phase.toLowerCase()) {
      case 'intensive':
        return 'Intensif';
      case 'continuation':
        return 'Lanjutan';
      default:
        return null;
    }
  }

  /// Label status terapi berbahasa Indonesia, mengikuti `TreatmentStatus`.
  String? get statusLabel {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'completed':
        return 'Selesai';
      case 'dropped':
        return 'Dihentikan';
      default:
        return null;
    }
  }

  String? get startDateLabel => formatIndonesianDate(therapyStart);

  String? get endDateLabel => formatIndonesianDate(therapyEnd);

  DateTime? get therapyStart {
    return _parseDate(therapyStartDate);
  }

  DateTime? get therapyEnd {
    return _parseDate(therapyEndDate);
  }

  /// Memilih pengobatan yang ditampilkan di Home dan Progress.
  ///
  /// Mengutamakan yang berstatus `active`. Bila ada lebih dari satu, atau
  /// tidak ada yang aktif, yang tanggal mulainya paling akhir dipakai.
  static MyTreatment? selectCurrent(List<MyTreatment> treatments) {
    if (treatments.isEmpty) return null;

    final List<MyTreatment> active = treatments
        .where((MyTreatment item) => item.isActive)
        .toList();
    final List<MyTreatment> pool =
        active.isNotEmpty ? active : List<MyTreatment>.from(treatments);

    pool.sort((MyTreatment a, MyTreatment b) {
      final DateTime? aStart = a.therapyStart;
      final DateTime? bStart = b.therapyStart;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return bStart.compareTo(aStart);
    });

    return pool.first;
  }

  /// Hari ke-n, total hari, minggu, dan porsi masa pengobatan, dihitung dari
  /// `therapy_start_date` serta `therapy_end_date`.
  ///
  /// Bernilai null bila tanggal tidak dapat diparse atau rentangnya tidak
  /// masuk akal, agar UI tetap menampilkan empty state.
  TreatmentProgress? get progress {
    final DateTime? start = therapyStart;
    final DateTime? end = therapyEnd;
    if (start == null || end == null) return null;
    if (end.isBefore(start)) return null;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return null;

    final int elapsedDays;
    if (today.isBefore(start)) {
      elapsedDays = 0;
    } else if (today.isAfter(end)) {
      elapsedDays = totalDays;
    } else {
      elapsedDays = today.difference(start).inDays + 1;
    }

    final int computedWeeks = (totalDays + 6) ~/ 7;
    final int totalWeeks = computedWeeks < 1 ? 1 : computedWeeks;
    final int elapsedWeeks;
    if (elapsedDays == 0) {
      elapsedWeeks = 0;
    } else {
      final int computedElapsed = ((elapsedDays - 1) ~/ 7) + 1;
      if (computedElapsed < 1) {
        elapsedWeeks = 1;
      } else if (computedElapsed > totalWeeks) {
        elapsedWeeks = totalWeeks;
      } else {
        elapsedWeeks = computedElapsed;
      }
    }

    final double rawFraction = elapsedDays / totalDays;
    final double fraction;
    if (rawFraction < 0) {
      fraction = 0;
    } else if (rawFraction > 1) {
      fraction = 1;
    } else {
      fraction = rawFraction;
    }

    return TreatmentProgress(
      elapsedDays: elapsedDays,
      totalDays: totalDays,
      elapsedWeeks: elapsedWeeks,
      totalWeeks: totalWeeks,
      fraction: fraction,
    );
  }

  static DateTime? _parseDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  String toString() =>
      'MyTreatment(id: $id, patientId: $patientId, status: $status)';
}

/// Nilai turunan dari tanggal pengobatan, bukan field backend.
class TreatmentProgress {
  const TreatmentProgress({
    required this.elapsedDays,
    required this.totalDays,
    required this.elapsedWeeks,
    required this.totalWeeks,
    required this.fraction,
  });

  /// Hari terapi yang sudah berjalan, termasuk hari ini.
  ///
  /// Dipakai bersama oleh [ProgressTimelineCard] dan [ProgressStreakCard]
  /// agar angka streak sama dengan "Hari ke-n" pada timeline.
  final int elapsedDays;
  final int totalDays;
  final int elapsedWeeks;
  final int totalWeeks;

  /// 0.0 sampai 1.0, untuk [LinearProgressIndicator].
  final double fraction;

  int get percent {
    final int value = (fraction * 100).round();
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  /// Temporary assumption: pasien dianggap selalu patuh selama hari terapi
  /// yang sudah berjalan. Bernilai null bila terapi belum dimulai.
  ///
  /// Bukan hasil AI VOT dan bukan hasil verifikasi dosis.
  ///
  // TODO: Saat backend sudah menyediakan actual medication adherence /
  // verified medication intake, ganti asumsi 100% ini dengan data aktual
  // untuk Progress dan Profile. Jangan menghitung kepatuhan dari
  // therapy_start_date / therapy_end_date lagi.
  double? get assumedAdherence {
    if (elapsedDays <= 0) return null;
    return 1.0;
  }
}
