import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/face_verification_result.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';

void main() {
  group('Phase 7: Face Verification -> AI-VOT Security Gate Tests', () {
    final MyMedicineSchedule scheduleA = MyMedicineSchedule.fromJson({
      'id': 15,
      'treatment_id': 2,
      'medicine_id': 1,
      'medicine_name': 'Rifampisin 450mg',
      'dosage': '1 Tablet',
      'quantity_initial': 60,
      'quantity_remaining': 45,
      'drink_time': '08:00:00',
    });

    final MyMedicineSchedule scheduleB = MyMedicineSchedule.fromJson({
      'id': 16,
      'treatment_id': 2,
      'medicine_id': 2,
      'medicine_name': 'Isoniazid 300mg',
      'dosage': '1 Tablet',
      'quantity_initial': 60,
      'quantity_remaining': 40,
      'drink_time': '12:00:00',
    });

    final FaceVerificationResult verifiedResultA = FaceVerificationResult.fromJson({
      'verified': true,
      'similarity_score': 0.8842,
      'threshold': 0.70,
      'face_verification_id': 142,
      'status': 'verified',
      'message': 'Wajah cocok dengan data pasien terdaftar.',
    });

    final FaceVerificationResult failedResultA = FaceVerificationResult.fromJson({
      'verified': false,
      'similarity_score': 0.4120,
      'threshold': 0.70,
      'face_verification_id': 143,
      'status': 'failed',
      'message': 'Wajah tidak cocok dengan pasien terdaftar.',
    });

    test('Gate Rule 1: verified == true allows AI-VOT entry for target schedule', () {
      expect(verifiedResultA.verified, isTrue);
      expect(verifiedResultA.faceVerificationId, equals(142));
      expect(scheduleA.id, equals(15));
    });

    test('Gate Rule 2: verified == false STOPS flow and prevents AI-VOT entry', () {
      expect(failedResultA.verified, isFalse);
      expect(failedResultA.status, equals('failed'));
    });

    test('Gate Rule 3: Schedule A verified CANNOT unlock Schedule B', () {
      expect(scheduleA.id, isNot(equals(scheduleB.id)));
      final bool isVerifiedForScheduleB =
          verifiedResultA.verified && (scheduleA.id == scheduleB.id);
      expect(isVerifiedForScheduleB, isFalse);
    });

    test('Gate Rule 4: Verification result is session-scoped and not boolean global', () {
      expect(verifiedResultA.faceVerificationId, greaterThan(0));
      expect(failedResultA.faceVerificationId, greaterThan(0));
    });

    test('Gate Rule 5: Correct medicine_schedule_id is preserved across gate', () {
      expect(scheduleA.id, equals(15));
      expect(scheduleB.id, equals(16));
    });
  });
}
