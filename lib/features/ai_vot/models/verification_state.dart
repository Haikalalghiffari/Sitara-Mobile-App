/// Jumlah tahap yang ditampilkan pada step indicator kamera.
const int kVerificationStepCount = 4;

/// State UI halaman AI-VOT.
enum VerificationState {
  ready,
  starting,
  faceVerifying,
  faceVerified,
  medicineDetecting,
  medicineMatched,
  drinking,
  completing,
  completed,
  needsReview,
}

extension VerificationStateX on VerificationState {
  String get statusLabel => switch (this) {
        VerificationState.ready => "Sistem siap",
        VerificationState.starting => "Menyiapkan sesi...",
        VerificationState.faceVerifying => "Memverifikasi wajah...",
        VerificationState.faceVerified => "Wajah terverifikasi",
        VerificationState.medicineDetecting => "Mendeteksi obat...",
        VerificationState.medicineMatched => "Obat sesuai",
        VerificationState.drinking => "Verifikasi visual proses minum",
        VerificationState.completing => "Memverifikasi proses minum...",
        VerificationState.completed => "Verifikasi minum obat berhasil",
        VerificationState.needsReview => "Menunggu pemeriksaan nakes",
      };

  String get instruction => switch (this) {
        VerificationState.ready =>
          "Posisikan wajah di dalam kamera, lalu mulai verifikasi",
        VerificationState.starting => "Menyiapkan sesi verifikasi",
        VerificationState.faceVerifying =>
          "Mohon tunggu, wajah sedang dicocokkan",
        VerificationState.faceVerified => "Wajah terverifikasi. Siapkan obat",
        VerificationState.medicineDetecting =>
          "Letakkan obat di dalam kotak",
        VerificationState.medicineMatched => "Obat sesuai jadwal",
        VerificationState.drinking =>
          "Minum obat seperti biasa di depan kamera",
        VerificationState.completing => "Memverifikasi proses minum...",
        VerificationState.completed => "Verifikasi minum obat berhasil.",
        VerificationState.needsReview =>
          "Video proses minum telah disimpan sebagai bukti. Silakan tunggu pemeriksaan dari tenaga kesehatan.",
      };

  bool get isProcessing => switch (this) {
        VerificationState.starting ||
        VerificationState.faceVerifying ||
        VerificationState.medicineDetecting ||
        VerificationState.drinking ||
        VerificationState.completing =>
          true,
        _ => false,
      };

  bool get showsMedicineGuide =>
      this == VerificationState.medicineDetecting ||
      this == VerificationState.medicineMatched;

  /// Layar tetap nyala hanya selama sesi VOT berjalan, bukan seluruh app.
  bool get keepScreenAwake => switch (this) {
        VerificationState.ready ||
        VerificationState.completed ||
        VerificationState.needsReview =>
          false,
        _ => true,
      };

  int get activeStepCount => switch (this) {
        VerificationState.ready ||
        VerificationState.starting ||
        VerificationState.faceVerifying =>
          1,
        VerificationState.faceVerified ||
        VerificationState.medicineDetecting =>
          2,
        VerificationState.medicineMatched ||
        VerificationState.drinking ||
        VerificationState.completing =>
          3,
        VerificationState.completed ||
        VerificationState.needsReview =>
          4,
      };
}
