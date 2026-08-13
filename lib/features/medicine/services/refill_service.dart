import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/refill.dart';

/// Akses permintaan pesan ulang obat milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class RefillService {
  RefillService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /refills/my`.
  ///
  /// Backend sudah menyaring berdasarkan pemegang token lewat join
  /// `refills → treatments → patients`, jadi hasilnya dipakai apa adanya tanpa
  /// penyaringan ulang di sisi aplikasi.
  Future<List<Refill>> getMyRefills() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myRefills,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengirim `POST /refills` dengan body `RefillCreate`.
  ///
  /// `treatment_id` wajib berasal dari `GET /treatments/my` dan `medicine_id`
  /// dari `GET /medicine-schedules/my`, karena backend menolak id yang bukan
  /// milik pasien yang sedang login.
  ///
  /// [description] bersifat opsional pada schema backend, jadi field-nya hanya
  /// dikirim ketika benar-benar berisi.
  Future<Refill> createRefill({
    required int treatmentId,
    required int medicineId,
    required int quantity,
    required String reason,
    String? description,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'treatment_id': treatmentId,
      'medicine_id': medicineId,
      'quantity': quantity,
      'reason': reason,
    };

    final String? detail = description?.trim();
    if (detail != null && detail.isNotEmpty) {
      body['description'] = detail;
    }

    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.refills,
        data: body,
      );

      return _parseSingle(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<Refill> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan riwayat pesan ulang tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Refill.fromJson)
        .toList();
  }

  Refill _parseSingle(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Format balasan pesan ulang tidak dikenali.',
      );
    }

    return Refill.fromJson(data);
  }
}
