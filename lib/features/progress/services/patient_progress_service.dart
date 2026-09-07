import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/patient_progress.dart';

/// Akses ringkasan kepatuhan milik pasien yang sedang login.
class PatientProgressService {
  PatientProgressService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /medications/progress`.
  Future<PatientProgress> getMyProgress() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.medicationsProgress,
      );

      final dynamic data = response.data;
      if (data is! Map) {
        throw const ApiException(
          'Format balasan perkembangan kepatuhan tidak dikenali.',
        );
      }

      return PatientProgress.fromJson(Map<String, dynamic>.from(data));
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
