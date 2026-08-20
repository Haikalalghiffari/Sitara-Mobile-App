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

  /// `PUT /auth/change-password`, body `current_password` dan `new_password`.
  static const String changePassword = '/auth/change-password';

  static const String patientProfile = '/patients/profile';

  /// `GET /treatments/my`, daftar pengobatan milik pemegang token.
  static const String myTreatments = '/treatments/my';

  /// `GET /medicine-schedules/my`, jadwal minum obat milik pemegang token.
  ///
  /// Bukan `/medicine-schedules`, yang mengembalikan jadwal seluruh pasien dan
  /// hanya dapat diakses role nakes.
  static const String myMedicineSchedules = '/medicine-schedules/my';

  /// `GET /control-schedules/my`, jadwal kontrol milik pemegang token.
  ///
  /// Bukan `/control-schedules`, yang mengembalikan jadwal seluruh pasien dan
  /// hanya dapat diakses role nakes.
  static const String myControlSchedules = '/control-schedules/my';

  /// `POST /complaints`, mengirim keluhan baru. Sejak backend memakai
  /// `require_nakes_or_patient`, endpoint ini dapat dipakai akun pasien.
  static const String complaints = '/complaints';

  /// `GET /complaints/my`, riwayat keluhan milik pemegang token.
  ///
  /// Bukan `/complaints`, yang mengembalikan keluhan seluruh pasien dan hanya
  /// dapat diakses role nakes.
  static const String myComplaints = '/complaints/my';

  /// `POST /refills`, mengirim permintaan pesan ulang obat. Sejak backend
  /// mengizinkan role patient, endpoint ini dapat dipakai akun pasien.
  static const String refills = '/refills';

  /// `GET /refills/my`, riwayat pesan ulang milik pemegang token.
  ///
  /// Bukan `/refills`, yang mengembalikan permintaan seluruh pasien dan hanya
  /// dapat diakses role nakes.
  static const String myRefills = '/refills/my';

  static const String notifications = '/notifications';

  /// `PUT /notifications/read-all`, menandai seluruh notifikasi milik pemegang
  /// token sebagai sudah dibaca.
  static const String notificationsReadAll = '/notifications/read-all';

  /// `DELETE /notifications/{notification_id}`.
  ///
  /// Backend tidak menyediakan penghapusan massal, hanya per notifikasi.
  static String notification(int id) => '/notifications/$id';

  /// `PUT /notifications/{notification_id}/read`, tanpa request body.
  static String notificationRead(int id) => '/notifications/$id/read';

  /// GET /face/status, mengecek status pendaftaran wajah pasien terautentikasi.
  static const String faceStatus = '/face/status';

  /// POST /face/register, mendaftarkan wajah pasien (multipart image).
  static const String faceRegister = '/face/register';

}
