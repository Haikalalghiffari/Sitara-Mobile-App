/// Response dari `GET /face/status`.
///
/// Field mengikuti [FaceStatusResponse] di backend.
class FaceStatus {
  const FaceStatus({
    required this.isRegistered,
    this.modelVersion,
    this.registeredAt,
  });

  final bool isRegistered;
  final String? modelVersion;
  final String? registeredAt;

  factory FaceStatus.fromJson(Map<String, dynamic> json) {
    return FaceStatus(
      isRegistered: json['is_registered'] as bool? ?? false,
      modelVersion: json['model_version']?.toString(),
      registeredAt: json['registered_at']?.toString(),
    );
  }
}
