import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/my_treatment.dart';

/// Akses data pengobatan milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class TreatmentService {
  TreatmentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /treatments/my`.
  ///
  /// Backend mengembalikan array `MyTreatmentResponse` milik pemegang token.
  Future<List<MyTreatment>> getMyTreatments() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myTreatments,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<MyTreatment> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan daftar pengobatan tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(MyTreatment.fromJson)
        .toList();
  }
}
