/// Model status pendaftaran wajah pasien dari backend SITARA (GET /face/status).
class FaceStatusResponse {
  const FaceStatusResponse({
    required this.isRegistered,
    this.modelVersion,
    this.registeredAt,
  });

  final bool isRegistered;
  final String? modelVersion;
  final DateTime? registeredAt;

  factory FaceStatusResponse.fromJson(Map<String, dynamic> json) {
    return FaceStatusResponse(
      isRegistered: json['is_registered'] as bool? ?? false,
      modelVersion: json['model_version'] as String?,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'] as String)
          : null,
    );
  }
}
