/// Jumlah tahap yang ditampilkan pada step indicator kamera.
const int kVerificationStepCount = 4;

/// State UI halaman AI-VOT Verifikasi.
///
/// Untuk sementara state ini digerakkan oleh simulasi. Ketika model AI
/// sudah terhubung, urutan state yang sama akan dihasilkan oleh pipeline
/// deteksi sebenarnya sehingga UI tidak perlu diubah.
enum VerificationState {
  ready,
  detectingFace,
  detectingMedicine,
  analyzingPose,
  verifying,
  success,
  failed,
}

extension VerificationStateX on VerificationState {
  /// Teks status singkat yang tampil pada pill di area kamera.
  String get statusLabel => switch (this) {
        VerificationState.ready => "Sistem siap",
        VerificationState.detectingFace => "Mendeteksi wajah...",
        VerificationState.detectingMedicine => "Mendeteksi obat...",
        VerificationState.analyzingPose => "Menganalisis posisi...",
        VerificationState.verifying => "Memverifikasi minum obat...",
        VerificationState.success => "Verifikasi berhasil",
        VerificationState.failed => "Verifikasi belum berhasil",
      };

  /// Instruksi utama untuk pasien.
  String get instruction => switch (this) {
        VerificationState.ready =>
          "Posisikan wajah dan tangan di dalam kamera",
        VerificationState.detectingFace => "Tetap arahkan wajah ke kamera",
        VerificationState.detectingMedicine => "Perlihatkan obat ke kamera",
        VerificationState.analyzingPose => "Dekatkan obat ke arah mulut",
        VerificationState.verifying => "Mohon tunggu sebentar",
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
        VerificationState.detectingFace =>
          1,
        VerificationState.detectingMedicine => 2,
        VerificationState.analyzingPose => 3,
        VerificationState.verifying || VerificationState.success => 4,
      };
}
