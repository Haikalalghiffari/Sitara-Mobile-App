/// Response `GET /medications/progress`.
///
/// Seluruh angka di sini dihitung backend. Flutter tidak menghitung ulang
/// adherence, tidak menghitung streak, dan tidak menentukan occurrence mana
/// yang terlewat. Tidak ada ambang waktu apa pun di sisi aplikasi.
class PatientProgress {
  const PatientProgress({
    required this.adherencePercentage,
    required this.successfulOccurrences,
    required this.failedOccurrences,
    required this.pendingReviewOccurrences,
    required this.finalDueOccurrences,
    required this.streakDays,
  });

  /// `adherence_percentage` dalam skala 0–100.
  ///
  /// Null bila backend menyatakan belum ada occurrence final. Null bukan 0 dan
  /// bukan 100: UI menampilkan keadaan "belum ada data".
  final double? adherencePercentage;

  /// `successful_occurrences`, occurrence yang dinyatakan berhasil backend.
  final int successfulOccurrences;

  /// `failed_occurrences`.
  final int failedOccurrences;

  /// `pending_review_occurrences`, menunggu pemeriksaan nakes.
  final int pendingReviewOccurrences;

  /// `final_due_occurrences`, occurrence yang sudah berstatus final.
  final int finalDueOccurrences;

  /// `streak_days` dari backend, bukan hitungan hari terapi.
  final int streakDays;

  factory PatientProgress.fromJson(Map<String, dynamic> json) {
    return PatientProgress(
      adherencePercentage: _decimal(json['adherence_percentage']),
      successfulOccurrences: _count(json['successful_occurrences']),
      failedOccurrences: _count(json['failed_occurrences']),
      pendingReviewOccurrences: _count(json['pending_review_occurrences']),
      finalDueOccurrences: _count(json['final_due_occurrences']),
      streakDays: _count(json['streak_days']),
    );
  }

  /// Backend dapat mengirim `88.9` maupun `89`. Nilai yang tidak terbaca
  /// menghasilkan null agar tidak ada persentase karangan.
  static double? _decimal(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Field jumlah yang absen dianggap 0, bukan menggagalkan seluruh parsing.
  static int _count(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  bool get hasAdherence => adherencePercentage != null;

  /// 0.0–1.0 untuk indikator lingkaran. Null bila belum ada data.
  double? get adherenceFraction {
    final double? value = adherencePercentage;
    if (value == null) return null;

    final double fraction = value / 100;
    if (fraction < 0) return 0;
    if (fraction > 1) return 1;
    return fraction;
  }

  /// `88.9%` atau `100%`. Null bila `adherence_percentage` null.
  ///
  /// Desimal dari backend dipertahankan; hanya `.0` yang dirapikan supaya
  /// angka bulat tidak tampil sebagai `100.0%`.
  String? get adherenceLabel {
    final double? value = adherencePercentage;
    if (value == null) return null;

    final double clamped = value < 0
        ? 0
        : value > 100
            ? 100
            : value;

    final String text = clamped == clamped.roundToDouble()
        ? clamped.round().toString()
        : clamped.toStringAsFixed(1);
    return '$text%';
  }

  @override
  String toString() =>
      'PatientProgress(adherencePercentage: $adherencePercentage, '
      'successfulOccurrences: $successfulOccurrences, '
      'failedOccurrences: $failedOccurrences, '
      'pendingReviewOccurrences: $pendingReviewOccurrences, '
      'finalDueOccurrences: $finalDueOccurrences, '
      'streakDays: $streakDays)';
}
