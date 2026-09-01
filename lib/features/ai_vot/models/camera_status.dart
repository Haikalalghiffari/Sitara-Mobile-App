/// Status perangkat kamera pada halaman AI-VOT.
///
/// Terpisah dari [VerificationState] karena ini menggambarkan kondisi
/// hardware kamera, bukan tahapan verifikasi.
enum CameraStatus {
  initializing,
  ready,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

extension CameraStatusX on CameraStatus {
  bool get isReady => this == CameraStatus.ready;

  bool get needsAppSettings => this == CameraStatus.permissionPermanentlyDenied;

  String get retryLabel => needsAppSettings ? "Buka Pengaturan" : "Coba Lagi";

  String get statusLabel => switch (this) {
    CameraStatus.initializing => "Menyiapkan kamera...",
    CameraStatus.ready => "Sistem siap",
    CameraStatus.permissionDenied ||
    CameraStatus.permissionPermanentlyDenied => "Izin kamera diperlukan",
    CameraStatus.unavailable => "Kamera tidak dapat digunakan",
  };

  String get description => switch (this) {
    CameraStatus.initializing || CameraStatus.ready => "Mohon tunggu sebentar",
    CameraStatus.permissionDenied => "Izin kamera diperlukan untuk verifikasi.",
    CameraStatus.permissionPermanentlyDenied =>
      "Izin kamera diperlukan untuk verifikasi. Aktifkan di pengaturan.",
    CameraStatus.unavailable =>
      "Periksa kamera perangkat Anda, lalu coba lagi.",
  };
}

/// Pemetaan kode [CameraException] ke status UI, tanpa mengubah paket kamera.
CameraStatus cameraStatusFromExceptionCode(String code) {
  return switch (code) {
    "CameraAccessDenied" => CameraStatus.permissionDenied,
    "CameraAccessDeniedWithoutPrompt" ||
    "CameraAccessRestricted" => CameraStatus.permissionPermanentlyDenied,
    _ => CameraStatus.unavailable,
  };
}
