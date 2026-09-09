import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_client.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/login/services/auth_service.dart';

void main() {
  test('change username memakai PUT /auth/change-username', () {
    expect(ApiEndpoints.changeUsername, '/auth/change-username');
    expect(ApiEndpoints.changePassword, '/auth/change-password');
    expect(ApiEndpoints.changeUsername, isNot(ApiEndpoints.changePassword));
  });

  test('payload memakai field backend new_username', () async {
    late RequestOptions captured;
    final AuthService service = _authService((RequestOptions options) {
      captured = options;
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{
          'message': 'Username berhasil diubah.',
          'username': 'pasienbaru',
        },
      );
    });

    final String message = await service.changeUsername(
      newUsername: 'pasienbaru',
    );

    expect(captured.method, 'PUT');
    expect(captured.path, ApiEndpoints.changeUsername);
    expect(captured.data, <String, String>{'new_username': 'pasienbaru'});
    expect(message, 'Username berhasil diubah.');
  });

  test('error backend diteruskan sebagai ApiException', () async {
    final AuthService service = _authService((RequestOptions options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 400,
          data: <String, dynamic>{
            'detail': 'Username sudah digunakan.',
          },
        ),
      );
    });

    expect(
      () => service.changeUsername(newUsername: 'sudahada'),
      throwsA(
        isA<ApiException>()
            .having(
              (ApiException error) => error.message,
              'message',
              'Username sudah digunakan.',
            )
            .having((ApiException error) => error.statusCode, 'status', 400),
      ),
    );
  });

  test('balasan tanpa message ditolak', () async {
    final AuthService service = _authService((RequestOptions options) {
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{'username': 'pasienbaru'},
      );
    });

    expect(
      () => service.changeUsername(newUsername: 'pasienbaru'),
      throwsA(isA<ApiException>()),
    );
  });
}

AuthService _authService(
  Response<dynamic> Function(RequestOptions options) onRequest,
) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        try {
          handler.resolve(onRequest(options));
        } catch (error) {
          if (error is DioException) {
            handler.reject(error);
            return;
          }
          handler.reject(
            DioException(requestOptions: options, error: error),
          );
        }
      },
    ),
  );

  return AuthService(apiClient: ApiClient(dio: dio));
}
