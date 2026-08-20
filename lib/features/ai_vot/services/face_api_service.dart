import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/face_registration_result.dart';
import '../models/face_status.dart';

/// Service untuk berkomunikasi dengan API Face Recognition backend SITARA.
///
/// Memakai [ApiClient] yang memasang header Authorization: Bearer <token>
/// secara otomatis dari penyimpanan sesi lokal.
class FaceApiService {
  FaceApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil GET /face/status dari backend.
  ///
  /// Source of truth status pendaftaran wajah berasal dari database backend.
  Future<FaceStatusResponse> getFaceStatus() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.faceStatus,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          'Format data status verifikasi wajah tidak valid.',
        );
      }

      return FaceStatusResponse.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengirim POST /face/register dengan berkas foto multipart/form-data.
  ///
  /// Zero-Trust Security: patient_id tidak pernah dikirim oleh client.
  /// Backend mengidentifikasi pasien berdasarkan token JWT terautentikasi.
  Future<FaceRegisterResponse> registerFace(String imagePath) async {
    try {
      final String fileName = imagePath.split('/').last.split('\\').last;

      final FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: fileName.isNotEmpty ? fileName : 'face.jpg',
        ),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.faceRegister,
        data: formData,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          'Format balasan pendaftaran wajah tidak valid.',
        );
      }

      return FaceRegisterResponse.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
