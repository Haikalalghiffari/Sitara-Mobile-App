import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/models/vot_complete_response.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';
import 'package:sitara/features/ai_vot/utils/today_medication_picker.dart';

void main() {
  group('Fase 2C: Mobile Retry & NEEDS_REVIEW Flow Tests', () {
    // 1. Face Verification Failure Scenarios
    test('Face failure with can_retry=true allows retry and stays on faceVerifying', () {
      final state = VotFlow.afterFaceVerify(
        verified: false,
        canRetry: true,
        isNeedsReview: false,
      );
      expect(state, VerificationState.faceVerifying);
      expect(VotFlow.retryTarget(state: state, phaseError: true), VotRetryTarget.face);
    });

    test('Face failure with can_retry=false escalates to needsReview and blocks retry', () {
      final state = VotFlow.afterFaceVerify(
        verified: false,
        canRetry: false,
        isNeedsReview: true,
      );
      expect(state, VerificationState.needsReview);
      expect(VotFlow.retryTarget(state: state, phaseError: false), isNull);
      expect(VotFlow.retryTarget(state: state, phaseError: true), isNull);
    });

    // 2. Medicine Detection Failure Scenarios
    test('Medicine failure with can_retry=true allows retry and stays on medicineDetecting', () {
      final state = VotFlow.afterMedicineDetect(
        medicineMatch: false,
        canRetry: true,
        isNeedsReview: false,
      );
      expect(state, VerificationState.medicineDetecting);
      expect(VotFlow.retryTarget(state: state, phaseError: true), VotRetryTarget.medicine);
    });

    test('Medicine failure with can_retry=false escalates to needsReview and blocks retry', () {
      final state = VotFlow.afterMedicineDetect(
        medicineMatch: false,
        canRetry: false,
        isNeedsReview: true,
      );
      expect(state, VerificationState.needsReview);
      expect(VotFlow.retryTarget(state: state, phaseError: false), isNull);
    });

    // 3. Drinking Failure Scenarios (maxStageReached before vs after nearMouth)
    test('Drinking failure with maxStageReached=waiting and can_retry=true stays on drinking for retry', () {
      final state = VotFlow.afterComplete(
        serverVerified: false,
        isNeedsReview: false,
        canRetry: true,
      );
      expect(state, VerificationState.drinking);
      expect(VotFlow.retryTarget(state: state, phaseError: true), VotRetryTarget.drinking);
    });

    test('Drinking failure after nearMouth with can_retry=false enters needsReview without asking to drink again', () {
      final state = VotFlow.afterComplete(
        serverVerified: false,
        isNeedsReview: true,
        canRetry: false,
      );
      expect(state, VerificationState.needsReview);
      expect(VotFlow.retryTarget(state: state, phaseError: false), isNull);
    });

    test('Drinking failure after withdrawing with can_retry=false enters needsReview without asking to drink again', () {
      final response = VotCompleteResponse.fromJson(<String, dynamic>{
        'daily_medication_id': 10,
        'status': 'needs_review',
        'vot_step': 'completed',
        'attempt_count': 1,
        'can_retry': false,
        'failure_reason': 'DRINKING_TIMEOUT',
        'max_drinking_stage': 'withdrawing',
        'message': 'Verifikasi memerlukan pemeriksaan tenaga kesehatan.',
      });

      expect(response.isNeedsReview, isTrue);
      expect(response.canRetry, isFalse);

      final state = VotFlow.afterComplete(
        serverVerified: response.isFinalSuccess,
        isNeedsReview: response.isNeedsReview,
        canRetry: response.canRetry,
      );
      expect(state, VerificationState.needsReview);
    });

    // 4. Third Attempt Escalation
    test('Third attempt failure with attempt_count=3 and can_retry=false enters needsReview', () {
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

      expect(response.attemptCount, 3);
      expect(response.canRetry, isFalse);
      expect(response.isNeedsReview, isTrue);

      final state = VotFlow.afterComplete(
        serverVerified: response.isFinalSuccess,
        isNeedsReview: response.isNeedsReview,
        canRetry: response.canRetry,
      );
      expect(state, VerificationState.needsReview);
    });

    // 5. Success
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

      final state = VotFlow.afterComplete(
        serverVerified: response.isFinalSuccess,
        isNeedsReview: response.isNeedsReview,
        canRetry: response.canRetry,
      );
      expect(state, VerificationState.completed);
    });

    // 6. Resuming session in needs_review state
    test('Session in needs_review state resumes into needsReview state', () {
      final state = VotFlow.afterStart(
        votStep: 'completed',
        status: 'needs_review',
      );
      expect(state, VerificationState.needsReview);
    });

    // 7. TodayMedicationPicker ignores needs_review items from eligible list
    test('TodayMedicationPicker excludes needs_review items from eligible list', () {
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
  });
}
