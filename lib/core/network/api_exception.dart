import 'package:dio/dio.dart';

/// Error jaringan/API yang sudah diterjemahkan menjadi pesan berbahasa
/// Indonesia yang aman ditampilkan langsung di UI.
///
/// Detail teknis (stack trace, body mentah) sengaja tidak diteruskan ke
/// pengguna agar tidak membocorkan informasi internal server.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  static const String connectionFailedMessage =
      'Server tidak dapat dihubungi. Periksa koneksi atau server backend.';

  static const String unexpectedMessage =
      'Terjadi kesalahan tidak terduga. Silakan coba lagi.';

  static const String methodNotAllowedMessage =
      'Metode request tidak sesuai dengan server.';

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(connectionFailedMessage);

      case DioExceptionType.badCertificate:
        return const ApiException(
          'Sertifikat keamanan server tidak valid.',
        );

      case DioExceptionType.cancel:
        return const ApiException('Permintaan dibatalkan.');

      case DioExceptionType.badResponse:
        return ApiException._fromResponse(error.response);

      case DioExceptionType.unknown:
        // Umumnya SocketException: server mati atau alamat salah.
        return const ApiException(connectionFailedMessage);
    }
  }

  factory ApiException._fromResponse(Response<dynamic>? response) {
    final int? status = response?.statusCode;
    final String? detail = _extractDetail(response?.data);

    final String message = switch (status) {
      400 => detail ?? 'Permintaan tidak valid.',
      401 => 'Sesi tidak valid atau telah berakhir. Silakan masuk kembali.',
      403 => 'Anda tidak memiliki akses ke layanan ini.',
      404 => 'Layanan tidak ditemukan di server.',
      405 => methodNotAllowedMessage,
      422 => detail ?? 'Data yang dikirim tidak sesuai format yang diminta.',
      _ =>
        status != null && status >= 500
            ? 'Terjadi gangguan pada server. Silakan coba beberapa saat lagi.'
            : detail ?? unexpectedMessage,
    };

    return ApiException(message, statusCode: status);
  }

  /// FastAPI mengirim pesan error pada field `detail`.
  ///
  /// Untuk error validasi (422) nilainya berupa list objek teknis, sehingga
  /// hanya `detail` bertipe String yang dianggap layak ditampilkan.
  static String? _extractDetail(dynamic data) {
    if (data is Map && data['detail'] is String) {
      final String detail = (data['detail'] as String).trim();
      return detail.isEmpty ? null : detail;
    }
    return null;
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, $message)';
}
