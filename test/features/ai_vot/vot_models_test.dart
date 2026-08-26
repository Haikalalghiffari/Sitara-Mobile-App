import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/vot_face_verify_result.dart';
import 'package:sitara/features/ai_vot/models/vot_medicine_detect_result.dart';
import 'package:sitara/features/ai_vot/models/vot_start_response.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';

void main() {
  test('parses POST /vot/start', () {
    final VotStartResponse result = VotStartResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 4,
      'status': 'in_progress',
      'vot_step': 'waiting',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '20:00:00',
    });
    expect(result.dailyMedicationId, 1);
    expect(result.votStep, 'waiting');
  });

  test('parses POST /vot/face-verify success', () {
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
    });
    expect(result.verified, isTrue);
    expect(result.faceVerificationId, 7);
    expect(result.votStep, 'face_verified');
  });

  test('parses POST /vot/medicine-detect match', () {
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
    });
    expect(result.medicineMatch, isTrue);
    expect(result.detectedMedicine, 'promag');
    expect(result.boundingBox?.x, 120);
    expect(result.boundingBox?.width, 200);
  });

  test('parses medicine detect with null detected_medicine', () {
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
