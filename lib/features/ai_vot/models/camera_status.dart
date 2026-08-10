/// Status perangkat kamera pada halaman AI-VOT.
///
/// Terpisah dari [VerificationState] karena ini menggambarkan kondisi
/// hardware kamera, bukan tahapan verifikasi.
enum CameraStatus {
  initializing,
  ready,
  permissionDenied,
  unavailable,
}

extension CameraStatusX on CameraStatus {
  bool get isReady => this == CameraStatus.ready;

  String get statusLabel => switch (this) {
        CameraStatus.initializing => "Menyiapkan kamera...",
        CameraStatus.ready => "Sistem siap",
        CameraStatus.permissionDenied => "Izin kamera diperlukan",
        CameraStatus.unavailable => "Kamera tidak dapat digunakan",
      };

  String get description => switch (this) {
        CameraStatus.initializing || CameraStatus.ready =>
          "Mohon tunggu sebentar",
        CameraStatus.permissionDenied =>
          "Berikan izin kamera agar verifikasi dapat dilakukan.",
        CameraStatus.unavailable =>
          "Periksa kamera perangkat Anda, lalu coba lagi.",
      };
}
