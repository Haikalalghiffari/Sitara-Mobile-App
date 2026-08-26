import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/models/vot_complete_response.dart';
import 'package:sitara/features/ai_vot/utils/vot_completion_guard.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';

void main() {
  test('face and medicine multipart IDs are daily_medication_id not schedule id',
      () {
    const int startedDailyId = 1;
    const int scheduleId = 4;
    expect(startedDailyId, isNot(scheduleId));
    expect(
      VotFlow.completeRequestBody(startedDailyId)!['daily_medication_id'],
      startedDailyId,
    );
  });

  test('MediaPipe local COMPLETED maps to COMPLETING not final COMPLETED', () {
    expect(
      VotFlow.afterLocalDrinkingCompleted(),
      VerificationState.completing,
    );
    expect(
      VotFlow.afterLocalDrinkingCompleted(),
      isNot(VerificationState.completed),
    );
  });

  test('complete body uses start daily_medication_id and drinking_verified', () {
    const int startedId = 1;
    final Map<String, Object>? body = VotFlow.completeRequestBody(startedId);

    expect(body, <String, Object>{
      'daily_medication_id': startedId,
      'drinking_verified': true,
    });
  });

  test('null or invalid daily_medication_id yields no request body', () {
    expect(VotFlow.completeRequestBody(null), isNull);
    expect(VotFlow.completeRequestBody(0), isNull);
    expect(VotFlow.completeRequestBody(-3), isNull);
  });

  test('parses POST /vot/complete success', () {
    final VotCompleteResponse result =
        VotCompleteResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'status': 'verified',
      'vot_step': 'verified',
      'completed_at': '2026-08-26T20:30:00',
      'message': 'Verifikasi minum obat berhasil.',
    });

    expect(result.dailyMedicationId, 1);
    expect(result.isFinalSuccess, isTrue);
    expect(result.completedAt, '2026-08-26T20:30:00');
    expect(result.message, 'Verifikasi minum obat berhasil.');
    expect(
      VotFlow.afterComplete(serverVerified: result.isFinalSuccess),
      VerificationState.completed,
    );
  });

  test('non-verified complete response is not final success', () {
    final VotCompleteResponse result =
        VotCompleteResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'status': 'in_progress',
      'vot_step': 'drinking',
      'completed_at': null,
      'message': 'Belum selesai.',
    });

    expect(result.isFinalSuccess, isFalse);
    expect(
      VotFlow.afterComplete(serverVerified: result.isFinalSuccess),
      VerificationState.completing,
    );
  });

  test('status verified without vot_step verified is not success', () {
    final VotCompleteResponse result =
        VotCompleteResponse.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'status': 'verified',
      'vot_step': 'drinking',
      'message': 'Tidak lengkap.',
    });
    expect(result.isFinalSuccess, isFalse);
  });

  test('guard blocks duplicate complete after first begin', () {
    final VotCompletionGuard guard = VotCompletionGuard();
    expect(guard.tryBegin(), isTrue);
    expect(guard.tryBegin(), isFalse);
    expect(guard.inFlight, isTrue);
  });

  test('guard allows retry after failure but not after success', () {
    final VotCompletionGuard guard = VotCompletionGuard();
    expect(guard.tryBegin(), isTrue);
    guard.markFailure();
    expect(guard.tryBegin(), isTrue);
    guard.markSuccess();
    expect(guard.tryBegin(), isFalse);
  });

  test('isServerVerified requires both status and vot_step', () {
    expect(
      VotFlow.isServerVerified(status: 'verified', votStep: 'verified'),
      isTrue,
    );
    expect(
      VotFlow.isServerVerified(status: 'verified', votStep: 'drinking'),
      isFalse,
    );
  });
}
