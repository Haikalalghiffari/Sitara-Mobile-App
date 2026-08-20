/// Model DTO request pembuatan video verification (POST /video-verifications).
class VideoVerificationRequest {
  const VideoVerificationRequest({
    required this.medicineScheduleId,
    this.faceVerificationId,
    required this.verificationDate,
    required this.videoPath,
    required this.fileName,
    this.mimeType = 'video/mp4',
    required this.fileSize,
    this.thumbnailPath,
  });

  final int medicineScheduleId;
  final int? faceVerificationId;
  final String verificationDate;
  final String videoPath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? thumbnailPath;

  Map<String, dynamic> toJson() {
    return {
      'medicine_schedule_id': medicineScheduleId,
      if (faceVerificationId != null) 'face_verification_id': faceVerificationId,
      'verification_date': verificationDate,
      'video_path': videoPath,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
    };
  }
}
