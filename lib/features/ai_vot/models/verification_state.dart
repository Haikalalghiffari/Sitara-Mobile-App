/// Jumlah tahap yang ditampilkan pada step indicator kamera.
const int kVerificationStepCount = 4;

/// State UI halaman AI-VOT. Satu halaman, tanpa klaim obat tertelan di server.
enum VerificationState {
  ready,
  starting,
  faceVerifying,
  faceVerified,
  medicineDetecting,
  medicineMatched,
  drinking,
  completed,
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
        VerificationState.completed => "Proses minum terdeteksi",
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
        VerificationState.completed =>
          "Proses minum terdeteksi. Hasil belum disimpan di server.",
      };

  bool get isProcessing => switch (this) {
        VerificationState.starting ||
        VerificationState.faceVerifying ||
        VerificationState.medicineDetecting ||
        VerificationState.drinking =>
          true,
        _ => false,
      };

  bool get showsMedicineGuide =>
      this == VerificationState.medicineDetecting ||
      this == VerificationState.medicineMatched;

  int get activeStepCount => switch (this) {
        VerificationState.ready ||
        VerificationState.starting ||
        VerificationState.faceVerifying =>
          1,
        VerificationState.faceVerified ||
        VerificationState.medicineDetecting =>
          2,
        VerificationState.medicineMatched ||
        VerificationState.drinking =>
          3,
        VerificationState.completed => 4,
      };
}
