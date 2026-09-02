import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/ai_vot/models/vot_complete_response.dart';
import 'package:sitara/features/ai_vot/models/vot_face_verify_result.dart';
import 'package:sitara/features/ai_vot/models/vot_medicine_detect_result.dart';
import 'package:sitara/features/ai_vot/models/vot_start_response.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';

void main() {
  test('parses POST /vot/start and keeps daily_medication_id distinct', () {
    final VotStartResponse result = VotStartResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 4,
      'status': 'in_progress',
      'vot_step': 'waiting',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '20:00:00',
    });
    expect(result.dailyMedicationId, 1);
    expect(result.medicineScheduleId, 4);
    expect(result.dailyMedicationId, isNot(result.medicineScheduleId));
    expect(result.votStep, 'waiting');
  });

  test('parses POST /vot/face-verify success with new retry fields', () {
    final VotFaceVerifyResult result =
        VotFaceVerifyResult.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 1,
      'face_verification_id': 7,
      'verified': true,
      'similarity_score': 0.87,
      'threshold': 0.7,
      'status': 'verified',
      'vot_step': 'face_verified',
      'message': 'Wajah cocok dengan data pasien terdaftar.',
      'attempt_count': 1,
      'can_retry': true,
      'failure_reason': null,
    });
    expect(result.verified, isTrue);
    expect(result.faceVerificationId, 7);
    expect(result.votStep, 'face_verified');
    expect(result.attemptCount, 1);
    expect(result.canRetry, isTrue);
    expect(result.failureReason, isNull);
  });

  test('parses POST /vot/face-verify backward compatible when retry fields omitted', () {
    final VotFaceVerifyResult result =
        VotFaceVerifyResult.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 1,
      'face_verification_id': 7,
      'verified': false,
      'similarity_score': 0.45,
      'threshold': 0.7,
      'status': 'in_progress',
      'vot_step': 'face_verifying',
      'message': 'Wajah tidak cocok.',
    });
    expect(result.verified, isFalse);
    expect(result.attemptCount, 0);
    expect(result.canRetry, isTrue);
    expect(result.failureReason, isNull);
  });

  test('parses POST /vot/medicine-detect match with retry fields', () {
    final VotMedicineDetectResult result =
        VotMedicineDetectResult.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 1,
      'expected_medicine': 'Promag',
      'detected_medicine': 'promag',
      'confidence': 0.94,
      'bounding_box': <String, dynamic>{
        'x': 120,
        'y': 80,
        'width': 200,
        'height': 250,
      },
      'medicine_match': true,
      'status': 'in_progress',
      'vot_step': 'medicine_matched',
      'message': 'Obat sesuai dengan jadwal.',
      'attempt_count': 1,
      'can_retry': true,
      'failure_reason': null,
    });
    expect(result.medicineMatch, isTrue);
    expect(result.detectedMedicine, 'promag');
    expect(result.boundingBox?.x, 120);
    expect(result.boundingBox?.width, 200);
    expect(result.attemptCount, 1);
    expect(result.canRetry, isTrue);
  });

  test('parses medicine detect backward compatible when retry fields omitted', () {
    final VotMedicineDetectResult result =
        VotMedicineDetectResult.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 1,
      'expected_medicine': 'Promag',
      'detected_medicine': null,
      'confidence': 0.0,
      'bounding_box': null,
      'medicine_match': false,
      'status': 'in_progress',
      'vot_step': 'face_verified',
      'message': 'Obat belum terdeteksi.',
    });
    expect(result.detectedMedicine, isNull);
    expect(result.medicineMatch, isFalse);
    expect(result.attemptCount, 0);
    expect(result.canRetry, isTrue);
  });

  test('parses POST /vot/complete with max_drinking_stage and failure_reason', () {
    final VotCompleteResponse result =
        VotCompleteResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'status': 'needs_review',
      'vot_step': 'completed',
      'completed_at': '2026-08-26T12:00:00Z',
      'message': 'Perlu ditinjau nakes',
      'attempt_count': 3,
      'can_retry': false,
      'failure_reason': 'DRINKING_TIMEOUT',
      'max_drinking_stage': 'nearMouth',
    });
    expect(result.dailyMedicationId, 1);
    expect(result.status, 'needs_review');
    expect(result.attemptCount, 3);
    expect(result.canRetry, isFalse);
    expect(result.failureReason, 'DRINKING_TIMEOUT');
    expect(result.maxDrinkingStage, 'nearMouth');
    expect(result.isFinalSuccess, isFalse);
  });

  test('parses DailyMedication with needs_review and attempt count', () {
    final DailyMedication item = DailyMedication.fromJson(<String, dynamic>{
      'daily_medication_id': 10,
      'medicine_schedule_id': 20,
      'medicine_id': 5,
      'medicine_name': 'Rifampisin',
      'dosage': '450mg',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '08:00:00',
      'quantity_remaining': 10,
      'status': 'needs_review',
      'vot_step': 'completed',
      'eligible': true,
      'attempt_count': 2,
      'can_retry': true,
      'failure_reason': 'MEDICINE_DETECTION_FAILED',
      'max_drinking_stage': 'handWithMedicine',
    });
    expect(item.isNeedsReview, isTrue);
    expect(item.attemptCount, 2);
    expect(item.canRetry, isTrue);
    expect(item.failureReason, 'MEDICINE_DETECTION_FAILED');
    expect(item.maxDrinkingStage, 'handWithMedicine');
  });

  test('face success goes to faceVerified', () {
    expect(
      VotFlow.afterFaceVerify(verified: true),
      VerificationState.faceVerified,
    );
  });

  test('face failure stays on faceVerifying', () {
    expect(
      VotFlow.afterFaceVerify(verified: false),
      VerificationState.faceVerifying,
    );
  });

  test('medicine match goes to medicineMatched', () {
    expect(
      VotFlow.afterMedicineDetect(medicineMatch: true),
      VerificationState.medicineMatched,
    );
  });

  test('medicine mismatch stays on medicineDetecting', () {
    expect(
      VotFlow.afterMedicineDetect(medicineMatch: false),
      VerificationState.medicineDetecting,
    );
  });

  test('start with face_verified skips to medicine', () {
    expect(
      VotFlow.afterStart(votStep: 'face_verified'),
      VerificationState.medicineDetecting,
    );
  });
}
