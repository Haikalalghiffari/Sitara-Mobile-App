import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/face_verification_result.dart';

/// Service untuk memanggil API Face Verification backend SITARA (POST /face/verify).
///
/// Memakai [ApiClient] yang memasang header Authorization: Bearer <token>
/// secara otomatis dari penyimpanan sesi lokal.
class FaceVerificationApiService {
  FaceVerificationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengirim foto tangkapan wajah dan medicine_schedule_id ke POST /face/verify.
  ///
  /// Zero-Trust Security: patient_id tidak pernah dikirim oleh client.
  /// Backend memvalidasi kepemilikan jadwal obat terhadap token JWT terautentikasi.
  Future<FaceVerificationResult> verifyFace({
    required String imagePath,
    required int medicineScheduleId,
  }) async {
    try {
      final String fileName = imagePath.split('/').last.split('\\').last;

      final FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: fileName.isNotEmpty ? fileName : 'verify.jpg',
        ),
        'medicine_schedule_id': medicineScheduleId.toString(),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.faceVerify,
        data: formData,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          'Format balasan verifikasi wajah tidak valid.',
        );
      }

      return FaceVerificationResult.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
