import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/patient_profile.dart';

/// Akses data pasien pada backend SITARA.
///
/// Memakai [ApiClient] yang sama dengan fitur authentication, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class PatientService {
  PatientService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /patients/profile`.
  ///
  /// Endpoint ini hanya dapat diakses oleh user dengan role `patient`.
  Future<PatientProfile> getPatientProfile() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.patientProfile,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          'Format balasan profil pasien tidak dikenali.',
        );
      }

      return PatientProfile.fromJson(data);
    } on DioException catch (error) {
      // Akun terautentikasi tetapi belum punya rekam data pasien.
      if (error.response?.statusCode == 404) {
        throw const ApiException(
          'Data pasien belum terdaftar untuk akun ini. '
          'Hubungi petugas Puskesmas.',
          statusCode: 404,
        );
      }
      throw ApiException.fromDioException(error);
    }
  }
}
