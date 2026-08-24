/// Jumlah tahap yang ditampilkan pada step indicator kamera.
const int kVerificationStepCount = 4;

/// State UI halaman AI-VOT Verifikasi.
///
/// Tahap ini hanya memverifikasi wajah lewat `POST /face/verify`.
/// Deteksi obat belum dihubungkan, jadi [faceVerified] bukan keberhasilan
/// sesi minum obat secara keseluruhan.
enum VerificationState {
  ready,
  detectingFace,
  detectingMedicine,
  analyzingPose,
  verifying,
  faceVerified,
  success,
  failed,
}

extension VerificationStateX on VerificationState {
  /// Teks status singkat yang tampil pada pill di area kamera.
  String get statusLabel => switch (this) {
        VerificationState.ready => "Sistem siap",
        VerificationState.detectingFace => "Memverifikasi wajah...",
        VerificationState.detectingMedicine => "Mendeteksi obat...",
        VerificationState.analyzingPose => "Menganalisis posisi...",
        VerificationState.verifying => "Memverifikasi minum obat...",
        VerificationState.faceVerified => "Wajah terverifikasi",
        VerificationState.success => "Verifikasi berhasil",
        VerificationState.failed => "Verifikasi belum berhasil",
      };

  /// Instruksi utama untuk pasien.
  String get instruction => switch (this) {
        VerificationState.ready =>
          "Posisikan wajah dan tangan di dalam kamera",
        VerificationState.detectingFace => "Mohon tunggu, wajah sedang dicocokkan",
        VerificationState.detectingMedicine => "Perlihatkan obat ke kamera",
        VerificationState.analyzingPose => "Dekatkan obat ke arah mulut",
        VerificationState.verifying => "Mohon tunggu sebentar",
        VerificationState.faceVerified =>
          "Wajah terverifikasi. Deteksi obat belum tersedia",
        VerificationState.success => "Terima kasih, verifikasi selesai",
        VerificationState.failed => "Silakan ulangi verifikasi",
      };

  /// Penjelasan singkat ketika verifikasi belum berhasil.
  String get failureReason =>
      "Wajah, obat, atau gerakan minum obat belum terlihat jelas.";

  bool get isProcessing => switch (this) {
        VerificationState.detectingFace ||
        VerificationState.detectingMedicine ||
        VerificationState.analyzingPose ||
        VerificationState.verifying =>
          true,
        _ => false,
      };

  /// Jumlah titik yang menyala pada step indicator.
  int get activeStepCount => switch (this) {
        VerificationState.ready ||
        VerificationState.failed ||
        VerificationState.faceVerified ||
        VerificationState.detectingFace =>
          1,
        VerificationState.detectingMedicine => 2,
        VerificationState.analyzingPose => 3,
        VerificationState.verifying || VerificationState.success => 4,
      };
}
