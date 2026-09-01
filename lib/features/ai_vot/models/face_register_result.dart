/// Response dari `POST /face/register`.
///
/// Field mengikuti [FaceRegisterResponse] di backend.
class FaceRegisterResult {
  const FaceRegisterResult({
    required this.status,
    required this.message,
    required this.modelVersion,
  });

  final String status;
  final String message;
  final String modelVersion;

  bool get isSuccess => status == 'success' && message.isNotEmpty;

  factory FaceRegisterResult.fromJson(Map<String, dynamic> json) {
    return FaceRegisterResult(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString().trim() ?? '',
      modelVersion: json['model_version']?.toString() ?? '',
    );
  }
}
