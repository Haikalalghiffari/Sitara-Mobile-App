/// Model balasan verifikasi wajah pasien dari backend SITARA (POST /face/verify).
class FaceVerificationResult {
  const FaceVerificationResult({
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

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json) {
    return FaceVerificationResult(
      verified: json['verified'] as bool? ?? false,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.70,
      faceVerificationId: (json['face_verification_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'failed',
      message: json['message']?.toString() ?? '',
    );
  }
}
