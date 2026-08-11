/// Konfigurasi koneksi ke backend SITARA (FastAPI).
///
/// Base URL sengaja dikumpulkan di satu tempat agar tidak tersebar
/// di banyak file. Untuk menjalankan aplikasi pada perangkat fisik
/// atau server lain, timpa nilainya saat build tanpa mengubah kode:
///
/// ```
/// flutter run --dart-define=SITARA_API_BASE_URL=http://192.168.1.10:8000
/// ```
class ApiConfig {
  const ApiConfig._();

  /// Alamat host machine dilihat dari dalam Android Emulator.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  static const String baseUrl = String.fromEnvironment(
    'SITARA_API_BASE_URL',
    defaultValue: androidEmulatorBaseUrl,
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}

/// Path endpoint backend. Harus persis sama dengan yang disediakan API.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String patientProfile = '/patients/profile';
}
