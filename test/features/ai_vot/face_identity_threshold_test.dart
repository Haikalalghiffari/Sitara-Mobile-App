import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/vot_face_verify_result.dart';
import 'package:sitara/features/ai_vot/utils/face_identity_threshold.dart';

VotFaceVerifyResult _result({
  required double similarity,
  bool verified = false,
}) {
  return VotFaceVerifyResult(
    dailyMedicationId: 1,
    medicineScheduleId: 1,
    faceVerificationId: 7,
    verified: verified,
    similarityScore: similarity,
    threshold: 0.70,
    status: 'in_progress',
    votStep: 'face_verifying',
    message: '',
  );
}

void main() {
  group('FaceIdentityThreshold', () {
    test('source of truth adalah 0.63', () {
      expect(FaceIdentityThreshold.value, 0.63);
    });

    test('1. similarity 0.62 → FAILED', () {
      expect(FaceIdentityThreshold.isMet(0.62), isFalse);
      expect(_result(similarity: 0.62).identityAccepted, isFalse);
    });

    test('2. similarity 0.6299 → FAILED', () {
      expect(FaceIdentityThreshold.isMet(0.6299), isFalse);
      expect(_result(similarity: 0.6299).identityAccepted, isFalse);
    });

    test('3. similarity 0.63 → VERIFIED', () {
      expect(FaceIdentityThreshold.isMet(0.63), isTrue);
      expect(_result(similarity: 0.63).identityAccepted, isTrue);
    });

    test('4. similarity 0.6392 → VERIFIED', () {
      expect(FaceIdentityThreshold.isMet(0.6392), isTrue);
      expect(_result(similarity: 0.6392).identityAccepted, isTrue);
    });

    test('5. similarity 0.70 → VERIFIED', () {
      expect(FaceIdentityThreshold.isMet(0.70), isTrue);
      expect(_result(similarity: 0.70).identityAccepted, isTrue);
    });

    test('6. similarity tinggi → VERIFIED', () {
      expect(FaceIdentityThreshold.isMet(0.95), isTrue);
      expect(_result(similarity: 0.95, verified: true).identityAccepted, isTrue);
    });

    test('ambang 0.63 mengalahkan flag verified backend yang tidak selaras', () {
      expect(
        _result(similarity: 0.63, verified: false).identityAccepted,
        isTrue,
      );
      expect(
        _result(similarity: 0.62, verified: true).identityAccepted,
        isFalse,
      );
    });

    test('fromJson memakai similarity_score, bukan flag verified backend', () {
      final VotFaceVerifyResult below =
          VotFaceVerifyResult.fromJson(<String, dynamic>{
        'daily_medication_id': 1,
        'medicine_schedule_id': 1,
        'face_verification_id': 7,
        'verified': true,
        'similarity_score': 0.6299,
        'threshold': 0.70,
        'status': 'in_progress',
        'vot_step': 'face_verifying',
        'message': '',
      });
      final VotFaceVerifyResult at =
          VotFaceVerifyResult.fromJson(<String, dynamic>{
        'daily_medication_id': 1,
        'medicine_schedule_id': 1,
        'face_verification_id': 7,
        'verified': false,
        'similarity_score': 0.63,
        'threshold': 0.70,
        'status': 'in_progress',
        'vot_step': 'face_verifying',
        'message': '',
      });

      expect(below.identityAccepted, isFalse);
      expect(at.identityAccepted, isTrue);
    });
  });
}
