/// Model balasan pendaftaran wajah pasien dari backend SITARA (POST /face/register).
class FaceRegisterResponse {
  const FaceRegisterResponse({
    required this.status,
    required this.message,
    this.modelVersion,
  });

  final String status;
  final String message;
  final String? modelVersion;

  factory FaceRegisterResponse.fromJson(Map<String, dynamic> json) {
    return FaceRegisterResponse(
      status: json['status'] as String? ?? 'success',
      message: json['message'] as String? ?? '',
      modelVersion: json['model_version'] as String?,
    );
  }
}
