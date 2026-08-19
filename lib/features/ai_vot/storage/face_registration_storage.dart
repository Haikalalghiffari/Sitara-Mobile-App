import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Status pendaftaran wajah di perangkat ini.
///
/// Hanya menyimpan boolean `faceRegistered`. Tidak menyimpan foto, embedding,
/// atau klaim bahwa wajah sudah ada di server. Backend register wajah
/// belum tersedia.
///
/// Memakai [FlutterSecureStorage] yang sudah ada di project. Kunci ini
/// terpisah dari token, jadi [TokenStorage.clear] saat logout tidak
/// menghapus status.
class FaceRegistrationStorage {
  FaceRegistrationStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _registeredKey = 'sitara.face_registered';

  Future<bool> isRegistered() async {
    final String? value = await _storage.read(key: _registeredKey);
    return value == 'true';
  }

  /// Menandai proses daftar wajah sudah selesai di perangkat.
  ///
  /// Tidak mengunggah apa pun. Tidak menyimpan berkas foto.
  Future<void> markRegistered() async {
    await _storage.write(key: _registeredKey, value: 'true');
  }
}
