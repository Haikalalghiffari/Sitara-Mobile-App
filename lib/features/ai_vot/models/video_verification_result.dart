/// Model DTO response pembuatan video verification dari backend (POST /video-verifications).
class VideoVerificationResult {
  const VideoVerificationResult({
    required this.id,
    required this.medicineScheduleId,
    this.faceVerificationId,
    required this.videoPath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailPath,
    required this.status,
  });

  final int id;
  final int medicineScheduleId;
  final int? faceVerificationId;
  final String videoPath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? thumbnailPath;
  final String status;

  factory VideoVerificationResult.fromJson(Map<String, dynamic> json) {
    return VideoVerificationResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      medicineScheduleId: (json['medicine_schedule_id'] as num?)?.toInt() ?? 0,
      faceVerificationId: (json['face_verification_id'] as num?)?.toInt(),
      videoPath: json['video_path']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'video/mp4',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      thumbnailPath: json['thumbnail_path']?.toString(),
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
