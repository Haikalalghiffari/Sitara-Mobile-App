import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';

/// HTTP client tunggal untuk seluruh komunikasi dengan backend SITARA.
///
/// Token otentikasi dilampirkan otomatis oleh interceptor, sehingga service
/// tidak perlu menyusun header `Authorization` satu per satu. Request yang
/// tidak boleh membawa token (misalnya login) dapat menonaktifkannya lewat
/// [noAuthOptions].
class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : dio = dio ?? Dio(_defaultOptions),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    this.dio.interceptors.add(
          InterceptorsWrapper(onRequest: _attachAuthorizationHeader),
        );
  }

  /// Instance bersama agar hanya ada satu connection pool di aplikasi.
  static final ApiClient instance = ApiClient();

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Penanda pada `Options.extra` untuk melewati pemasangan token.
  static const String _requiresAuthKey = 'requiresAuth';

  /// Dipakai oleh endpoint publik seperti login.
  static Options noAuthOptions() {
    return Options(extra: const {_requiresAuthKey: false});
  }

  static BaseOptions get _defaultOptions => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      );

  Future<void> _attachAuthorizationHeader(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool requiresAuth = options.extra[_requiresAuthKey] != false;

    if (requiresAuth) {
      final String? authorization =
          await _tokenStorage.readAuthorizationHeader();

      if (authorization != null) {
        options.headers['Authorization'] = authorization;
      }
    }

    handler.next(options);
  }
}
