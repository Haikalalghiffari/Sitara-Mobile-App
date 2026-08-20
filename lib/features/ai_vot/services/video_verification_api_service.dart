import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../models/video_verification_request.dart';
import '../models/video_verification_result.dart';

/// Service untuk menangani pengiriman Video Verification ke endpoint POST /video-verifications.
class VideoVerificationApiService {
  VideoVerificationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Mengirim record Video Verification beserta ace_verification_id ke backend SITARA.
  Future<VideoVerificationResult> createVideoVerification({
    required VideoVerificationRequest request,
    required String token,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.videoVerifications,
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VideoVerificationResult.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        json['detail']?.toString() ?? 'Gagal membuat verifikasi video',
      );
    }
  }
}
