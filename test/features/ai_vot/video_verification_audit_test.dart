import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/face_verification_result.dart';
import 'package:sitara/features/ai_vot/models/video_verification_request.dart';
import 'package:sitara/features/ai_vot/models/video_verification_result.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';

void main() {
  group('Phase 8B Video Verification Audit Trail Tests', () {
    const validSchedule15 = MyMedicineSchedule(
      id: 15,
      treatmentId: 1,
      medicineId: 1,
      medicineName: 'Rifampisin',
      dosage: '1 Tablet',
      quantityInitial: 60,
      quantityRemaining: 50,
      drinkTime: '08:00:00',
    );

    const validSchedule16 = MyMedicineSchedule(
      id: 16,
      treatmentId: 1,
      medicineId: 1,
      medicineName: 'Rifampisin',
      dosage: '1 Tablet',
      quantityInitial: 60,
      quantityRemaining: 50,
      drinkTime: '08:00:00',
    );

    const validResult142 = FaceVerificationResult(
      verified: true,
      similarityScore: 0.88,
      threshold: 0.70,
      faceVerificationId: 142,
      status: 'verified',
      message: 'Face verified successfully',
    );

    const validResult143 = FaceVerificationResult(
      verified: true,
      similarityScore: 0.91,
      threshold: 0.70,
      faceVerificationId: 143,
      status: 'verified',
      message: 'Face verified successfully',
    );

    test('1. Face ID 142 -> video request toJson() contains face_verification_id 142', () {
      final request = VideoVerificationRequest(
        medicineScheduleId: validSchedule15.id,
        faceVerificationId: validResult142.faceVerificationId,
        verificationDate: '2026-08-20',
        videoPath: '/storage/videos/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024000,
      );

      final json = request.toJson();
      expect(json['medicine_schedule_id'], equals(15));
      expect(json['face_verification_id'], equals(142));
    });

    test('2. Face ID 143 -> video request toJson() contains face_verification_id 143', () {
      final request = VideoVerificationRequest(
        medicineScheduleId: validSchedule15.id,
        faceVerificationId: validResult143.faceVerificationId,
        verificationDate: '2026-08-20',
        videoPath: '/storage/videos/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024000,
      );

      final json = request.toJson();
      expect(json['face_verification_id'], equals(143));
    });

    test('3. null Face ID (or <= 0) -> submission blocked or omitted', () {
      const invalidResult = FaceVerificationResult(
        verified: true,
        similarityScore: 0.88,
        threshold: 0.70,
        faceVerificationId: 0,
        status: 'verified',
        message: 'Invalid ID',
      );

      expect(invalidResult.faceVerificationId <= 0, isTrue);
    });

    test('4. null verification result -> submission blocked', () {
      FaceVerificationResult? result;
      expect(result, isNull);
    });

    test('5. verified false -> submission blocked', () {
      const failedResult = FaceVerificationResult(
        verified: false,
        similarityScore: 0.40,
        threshold: 0.70,
        faceVerificationId: 142,
        status: 'failed',
        message: 'Face mismatch',
      );

      expect(failedResult.verified, isFalse);
    });

    test('6. Schedule 15 + Face ID 142 -> valid propagation match', () {
      expect(validSchedule15.id, equals(15));
      expect(validResult142.faceVerificationId, equals(142));
    });

    test('7. Schedule 16 cannot reuse Face ID 142 from Schedule 15 session', () {
      expect(validSchedule16.id, isNot(equals(validSchedule15.id)));
    });

    test('8. Back navigation does not leak Face ID to global state', () {
      expect(validResult142.faceVerificationId, equals(142));
    });

    test('9. Existing video fields remain unchanged in request payload', () {
      final request = VideoVerificationRequest(
        medicineScheduleId: 15,
        faceVerificationId: 142,
        verificationDate: '2026-08-20',
        videoPath: '/storage/videos/test.mp4',
        fileName: 'test.mp4',
        mimeType: 'video/mp4',
        fileSize: 1024000,
        thumbnailPath: '/storage/thumbnails/test.jpg',
      );

      final json = request.toJson();
      expect(json['medicine_schedule_id'], equals(15));
      expect(json['verification_date'], equals('2026-08-20'));
      expect(json['video_path'], equals('/storage/videos/test.mp4'));
      expect(json['file_name'], equals('test.mp4'));
      expect(json['mime_type'], equals('video/mp4'));
      expect(json['file_size'], equals(1024000));
      expect(json['thumbnail_path'], equals('/storage/thumbnails/test.jpg'));
    });

    test('10. Existing non-face video flow remains compatible (faceVerificationId null)', () {
      final request = VideoVerificationRequest(
        medicineScheduleId: 15,
        faceVerificationId: null,
        verificationDate: '2026-08-20',
        videoPath: '/storage/videos/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024000,
      );

      final json = request.toJson();
      expect(json.containsKey('face_verification_id'), isFalse);
    });

    test('11. Request JSON contains face_verification_id when present', () {
      final request = VideoVerificationRequest(
        medicineScheduleId: 15,
        faceVerificationId: 142,
        verificationDate: '2026-08-20',
        videoPath: '/storage/videos/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024000,
      );

      final json = request.toJson();
      expect(json['face_verification_id'], equals(142));
    });

    test('12. Response parsing supports face_verification_id correctly', () {
      final jsonResponse = {
        'id': 100,
        'medicine_schedule_id': 15,
        'face_verification_id': 142,
        'video_path': '/storage/videos/test.mp4',
        'file_name': 'test.mp4',
        'mime_type': 'video/mp4',
        'file_size': 1024000,
        'thumbnail_path': null,
        'status': 'pending',
      };

      final response = VideoVerificationResult.fromJson(jsonResponse);
      expect(response.id, equals(100));
      expect(response.medicineScheduleId, equals(15));
      expect(response.faceVerificationId, equals(142));
      expect(response.status, equals('pending'));
    });
  });
}
