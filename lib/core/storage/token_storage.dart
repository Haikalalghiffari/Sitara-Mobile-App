import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan access token pada storage terenkripsi milik OS
/// (Android Keystore / iOS Keychain).
///
/// Hanya token yang disimpan. Password pengguna tidak pernah ditulis
/// ke penyimpanan mana pun.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'sitara.access_token';
  static const String _tokenTypeKey = 'sitara.token_type';

  Future<void> saveToken({
    required String accessToken,
    required String tokenType,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _tokenTypeKey, value: tokenType);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  /// Nilai siap pakai untuk header `Authorization`, misalnya `Bearer abc123`.
  ///
  /// Mengembalikan `null` bila belum ada token tersimpan.
  Future<String?> readAuthorizationHeader() async {
    final String? accessToken = await readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final String? tokenType = await _storage.read(key: _tokenTypeKey);
    final String scheme = (tokenType == null || tokenType.isEmpty)
        ? 'Bearer'
        : _capitalize(tokenType);

    return '$scheme $accessToken';
  }

  Future<bool> hasToken() async {
    final String? accessToken = await readAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _tokenTypeKey);
  }

  /// Backend mengirim `"bearer"` (huruf kecil), sedangkan skema pada header
  /// HTTP lazim ditulis `"Bearer"`.
  static String _capitalize(String value) {
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
