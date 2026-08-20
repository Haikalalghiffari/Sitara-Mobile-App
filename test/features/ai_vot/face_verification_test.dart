import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/face_verification_result.dart';
import 'package:sitara/features/ai_vot/models/face_verification_state.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';

void main() {
  group('FaceVerificationResult Model Tests', () {
    test('fromJson parses verified response correctly', () {
      final Map<String, dynamic> json = {
        'verified': true,
        'similarity_score': 0.8842,
        'threshold': 0.70,
        'face_verification_id': 142,
        'status': 'verified',
        'message': 'Wajah cocok dengan data pasien terdaftar.',
      };

      final FaceVerificationResult result = FaceVerificationResult.fromJson(json);

      expect(result.verified, isTrue);
      expect(result.similarityScore, equals(0.8842));
      expect(result.threshold, equals(0.70));
      expect(result.faceVerificationId, equals(142));
      expect(result.status, equals('verified'));
      expect(result.message, equals('Wajah cocok dengan data pasien terdaftar.'));
    });

    test('fromJson parses failed response correctly', () {
      final Map<String, dynamic> json = {
        'verified': false,
        'similarity_score': 0.4120,
        'threshold': 0.70,
        'face_verification_id': 143,
        'status': 'failed',
        'message': 'Wajah tidak cocok dengan pasien terdaftar.',
      };

      final FaceVerificationResult result = FaceVerificationResult.fromJson(json);

      expect(result.verified, isFalse);
      expect(result.similarityScore, equals(0.4120));
      expect(result.threshold, equals(0.70));
      expect(result.faceVerificationId, equals(143));
      expect(result.status, equals('failed'));
      expect(result.message, equals('Wajah tidak cocok dengan pasien terdaftar.'));
    });
  });

  group('MyMedicineSchedule ID Parsing Tests', () {
    test('fromJson parses id field correctly for POST /face/verify', () {
      final Map<String, dynamic> json = {
        'id': 15,
        'treatment_id': 2,
        'medicine_id': 1,
        'medicine_name': 'Rifampisin 450mg',
        'dosage': '1 Tablet',
        'quantity_initial': 60,
        'quantity_remaining': 45,
        'drink_time': '08:00:00',
      };

      final MyMedicineSchedule schedule = MyMedicineSchedule.fromJson(json);

      expect(schedule.id, equals(15));
      expect(schedule.treatmentId, equals(2));
      expect(schedule.medicineName, equals('Rifampisin 450mg'));
    });
  });

  group('FaceVerificationState Enum Tests', () {
    test('Enum values cover all required verification states', () {
      expect(FaceVerificationState.values, contains(FaceVerificationState.initial));
      expect(FaceVerificationState.values, contains(FaceVerificationState.capturing));
      expect(FaceVerificationState.values, contains(FaceVerificationState.verifying));
      expect(FaceVerificationState.values, contains(FaceVerificationState.verified));
      expect(FaceVerificationState.values, contains(FaceVerificationState.failed));
    });
  });
}
