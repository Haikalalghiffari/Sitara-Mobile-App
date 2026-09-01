/// Response dari `POST /face/verify`.
///
/// Field mengikuti [FaceVerifyResponse] di backend.
class FaceVerifyResult {
  const FaceVerifyResult({
    required this.verified,
    required this.similarityScore,
    required this.threshold,
    required this.faceVerificationId,
    required this.status,
    required this.message,
  });

  final bool verified;
  final double similarityScore;
  final double threshold;
  final int faceVerificationId;
  final String status;
  final String message;

  factory FaceVerifyResult.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResult(
      verified: json['verified'] as bool? ?? false,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      faceVerificationId: (json['face_verification_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString().trim() ?? '',
    );
  }
}
