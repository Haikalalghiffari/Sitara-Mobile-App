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
        VerificationState.medicineMatched => "Obat terdeteksi",
        VerificationState.drinking => "Sedang merekam...",
        VerificationState.completing => "Mengirim video...",
        VerificationState.completed => "Verifikasi selesai",
        VerificationState.needsReview => "Menunggu verifikasi nakes",
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
        VerificationState.medicineMatched =>
          "Tekan 'Mulai Rekam' untuk merekam proses minum obat",
        VerificationState.drinking =>
          "Silakan minum obat Anda di depan kamera, lalu tekan Selesai Minum Obat",
        VerificationState.completing => "Sedang mengunggah dan memproses...",
        VerificationState.completed => "Verifikasi minum obat berhasil.",
        VerificationState.needsReview =>
          "Verifikasi memerlukan review tenaga kesehatan.",
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
        VerificationState.completed => 4,
        // needsReview hanya setelah video analysis, bukan completed.
        VerificationState.needsReview => 3,
      };
}
