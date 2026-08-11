import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_token.dart';
import '../models/user_profile.dart';

/// Otentikasi terhadap backend SITARA.
///
/// Seluruh kegagalan dilaporkan sebagai [ApiException] yang pesannya sudah
/// siap ditampilkan di UI.
class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient.instance,
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  static const String invalidCredentialsMessage =
      'Username atau password salah.';

  /// Menukar kredensial dengan access token, menyimpannya, lalu mengambil
  /// profil pengguna dari backend.
  Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    final AuthToken token = await _requestToken(
      username: username,
      password: password,
    );

    await _tokenStorage.saveToken(
      accessToken: token.accessToken,
      tokenType: token.tokenType,
    );

    return getProfile();
  }

  Future<AuthToken> _requestToken({
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.login,
        data: <String, String>{
          'username': username,
          'password': password,
        },
        options: ApiClient.noAuthOptions(),
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Format balasan login tidak dikenali.');
      }

      final AuthToken token = AuthToken.fromJson(data);
      if (!token.isValid) {
        throw const ApiException('Server tidak mengirimkan access token.');
      }

      return token;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const ApiException(
          invalidCredentialsMessage,
          statusCode: 401,
        );
      }
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengambil `GET /auth/profile` memakai token tersimpan.
  Future<UserProfile> getProfile() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.profile,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Format balasan profil tidak dikenali.');
      }

      return UserProfile.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // Token ditolak backend, jangan simpan kredensial yang tidak berlaku.
        await _tokenStorage.clear();
      }
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasActiveSession() => _tokenStorage.hasToken();
}
