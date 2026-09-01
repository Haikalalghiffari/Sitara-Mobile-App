import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/video_verification_request.dart';
import '../models/video_verification_result.dart';

/// Service untuk menangani pengiriman Video Verification ke endpoint POST /video-verifications.
class VideoVerificationApiService {
  VideoVerificationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengirim record Video Verification beserta face_verification_id ke backend SITARA.
  Future<VideoVerificationResult> createVideoVerification({
    required VideoVerificationRequest request,
    String? token,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.videoVerifications,
        data: request.toJson(),
        options: token != null
            ? Options(headers: <String, dynamic>{'Authorization': 'Bearer $token'})
            : null,
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          'Format balasan verifikasi video tidak valid.',
        );
      }

      return VideoVerificationResult.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
