import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/models/vot_complete_response.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';
import 'package:sitara/features/ai_vot/utils/today_medication_picker.dart';

void main() {
  group('AI VOT retry, reset, and video-only needsReview', () {
    test('Face failure attempt 1 stays on faceVerifying and allows retry', () {
      final state = VotFlow.afterFaceVerify(verified: false);
      expect(state, VerificationState.faceVerifying);
      expect(state, isNot(VerificationState.needsReview));
      expect(state, isNot(VerificationState.completed));
      expect(state, isNot(VerificationState.medicineDetecting));
      expect(
        VotFlow.retryTarget(state: state, phaseError: true),
        VotRetryTarget.face,
      );
      expect(VotFlow.reachedMaxAttempts(1), isFalse);
    });

    test('Face failure attempt 2 stays on faceVerifying and allows retry', () {
      final state = VotFlow.afterFaceVerify(
        verified: false,
        canRetry: true,
        isNeedsReview: false,
      );
      expect(state, VerificationState.faceVerifying);
      expect(state, isNot(VerificationState.needsReview));
      expect(VotFlow.reachedMaxAttempts(2), isFalse);
      expect(
        VotFlow.retryTarget(
          state: state,
          phaseError: true,
          maxAttemptsReached: false,
        ),
        VotRetryTarget.face,
      );
    });

    test('Face failure attempt 3 stays on faceVerifying, never needsReview', () {
      final state = VotFlow.afterFaceVerify(
        verified: false,
        canRetry: false,
        isNeedsReview: true,
      );
      expect(state, VerificationState.faceVerifying);
      expect(state, isNot(VerificationState.needsReview));
      expect(state, isNot(VerificationState.completed));
      expect(VotFlow.reachedMaxAttempts(3), isTrue);
      expect(
        VotFlow.retryTarget(
          state: state,
          phaseError: true,
          maxAttemptsReached: true,
        ),
        isNull,
      );
      expect(VotFlow.faceMaxAttemptMessage, contains('3 percobaan'));
    });

    test('Face restart helper does not treat abandoned session as video review', () {
      expect(
        VotFlow.isVideoNeedsReview(status: 'needs_review', votStep: 'waiting'),
        isFalse,
      );
      expect(
        VotFlow.isVideoNeedsReview(
          status: 'needs_review',
          votStep: 'face_verifying',
        ),
        isFalse,
      );
      expect(
        VotFlow.afterStart(votStep: 'waiting', status: 'needs_review'),
        VerificationState.faceVerifying,
      );
    });

    test('Medicine failure stays on medicineDetecting, never needsReview', () {
      final retryState = VotFlow.afterMedicineDetect(medicineMatch: false);
      expect(retryState, VerificationState.medicineDetecting);
      expect(retryState, isNot(VerificationState.needsReview));
      expect(retryState, isNot(VerificationState.drinking));
      expect(
        VotFlow.retryTarget(state: retryState, phaseError: true),
        VotRetryTarget.medicine,
      );

      final maxState = VotFlow.afterMedicineDetect(
        medicineMatch: false,
        canRetry: false,
        isNeedsReview: true,
      );
      expect(maxState, VerificationState.medicineDetecting);
      expect(maxState, isNot(VerificationState.needsReview));
      expect(VotFlow.medicineMaxAttemptMessage, contains('mulai ulang'));
    });

    test('Medicine success goes to medicineMatched', () {
      expect(
        VotFlow.afterMedicineDetect(medicineMatch: true),
        VerificationState.medicineMatched,
      );
    });

    test('Face success goes to faceVerified', () {
      expect(
        VotFlow.afterFaceVerify(verified: true),
        VerificationState.faceVerified,
      );
    });

    test('Drinking failure after video analysis enters needsReview', () {
      final state = VotFlow.afterComplete(
        serverVerified: false,
        isNeedsReview: true,
        canRetry: false,
      );
      expect(state, VerificationState.needsReview);
      expect(state.activeStepCount, 3);
      expect(state, isNot(VerificationState.completed));
    });

    test('Drinking timeout is video needsReview', () {
      expect(
        VotFlow.afterDrinkingTimeout(),
        VerificationState.needsReview,
      );
    });

    test('Third drinking attempt with can_retry=false is still video needsReview', () {
      final response = VotCompleteResponse.fromJson(<String, dynamic>{
        'daily_medication_id': 10,
        'status': 'needs_review',
        'vot_step': 'completed',
        'attempt_count': 3,
        'can_retry': false,
        'failure_reason': 'DRINKING_TIMEOUT',
        'max_drinking_stage': 'waiting',
        'message': 'Batas maksimal 3 percobaan tercapai. Verifikasi diteruskan ke Nakes.',
      });

      expect(response.isNeedsReview, isTrue);
      expect(
        VotFlow.isVideoNeedsReview(
          status: response.status,
          votStep: response.votStep,
        ),
        isTrue,
      );
      expect(
        VotFlow.afterComplete(serverVerified: response.isFinalSuccess),
        VerificationState.needsReview,
      );
    });

    test('Successful drinking with status=verified enters completed', () {
      final response = VotCompleteResponse.fromJson(<String, dynamic>{
        'daily_medication_id': 10,
        'status': 'verified',
        'vot_step': 'verified',
        'attempt_count': 1,
        'can_retry': false,
        'message': 'Verifikasi minum obat berhasil.',
      });

      expect(response.isFinalSuccess, isTrue);
      expect(
        VotFlow.afterComplete(serverVerified: response.isFinalSuccess),
        VerificationState.completed,
      );
    });

    test('Video needs_review session resumes into needsReview', () {
      final state = VotFlow.afterStart(
        votStep: 'completed',
        status: 'needs_review',
      );
      expect(state, VerificationState.needsReview);
      expect(
        VotFlow.reviewOriginFromVotStep('completed'),
        VotReviewOrigin.drinking,
      );
    });

    test('Face-stage needs_review does not resume as needsReview', () {
      expect(
        VotFlow.afterSession(votStep: 'waiting', status: 'needs_review'),
        VerificationState.faceVerifying,
      );
      expect(
        VotFlow.isVideoNeedsReview(status: 'needs_review', votStep: 'waiting'),
        isFalse,
      );
    });

    test('TodayMedicationPicker excludes video needs_review from eligible list', () {
      final itemNeedsReview = DailyMedication.fromJson(<String, dynamic>{
        'daily_medication_id': 1,
        'medicine_schedule_id': 1,
        'medicine_name': 'Rifampisin',
        'dosage': '450mg',
        'scheduled_date': '2026-09-02',
        'scheduled_time': '08:00:00',
        'status': 'needs_review',
        'vot_step': 'completed',
        'eligible': true,
      });

      final snapshot = TodayMedicationPicker.inspect([itemNeedsReview]);
      expect(snapshot.kind, VotScheduleKind.finished);
      expect(snapshot.selected, isNull);
    });

    test('Face-stage needs_review stays selectable, not finished', () {
      final item = DailyMedication.fromJson(<String, dynamic>{
        'daily_medication_id': 1,
        'medicine_schedule_id': 1,
        'medicine_name': 'Rifampisin',
        'dosage': '450mg',
        'scheduled_date': '2026-09-02',
        'scheduled_time': '08:00:00',
        'status': 'needs_review',
        'vot_step': 'waiting',
        'eligible': false,
        'attempt_count': 3,
        'can_retry': false,
      });

      expect(item.canStartOrResume, isTrue);
      expect(
        VotFlow.isDoseFinishedForPatient(
          status: item.status,
          votStep: item.votStep,
        ),
        isFalse,
      );
      final snapshot = TodayMedicationPicker.inspect([item]);
      expect(snapshot.kind, VotScheduleKind.eligible);
      expect(snapshot.selected?.dailyMedicationId, 1);
      expect(snapshot.message, isNot(TodayMedicationPicker.allFinishedMessage()));
    });

    test('complete is not implied by face or medicine max attempts', () {
      expect(VotFlow.completeRequestBody(7), isNotNull);
      expect(
        VotFlow.afterFaceVerify(verified: false, canRetry: false),
        isNot(VerificationState.completed),
      );
      expect(
        VotFlow.afterMedicineDetect(medicineMatch: false, canRetry: false),
        isNot(VerificationState.completed),
      );
    });

    test('old session GET with abandoned face step does not map to completed', () {
      expect(
        VotFlow.afterSession(votStep: 'completed'),
        isNot(VerificationState.completed),
      );
      expect(
        VotFlow.isServerVerified(status: 'needs_review', votStep: 'verified'),
        isFalse,
      );
      expect(
        VotFlow.isServerVerified(status: 'in_progress', votStep: 'waiting'),
        isFalse,
      );
    });
  });
}
