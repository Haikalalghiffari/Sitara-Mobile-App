import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/models/vot_complete_response.dart';
import 'package:sitara/features/ai_vot/utils/drinking_sequence.dart';
import 'package:sitara/features/ai_vot/utils/vot_completion_guard.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';
import 'package:sitara/features/ai_vot/utils/vot_screen_awake.dart';

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

  test('guard reset allows a new complete attempt', () {
    final VotCompletionGuard guard = VotCompletionGuard();
    expect(guard.tryBegin(), isTrue);
    guard.markSuccess();
    expect(guard.tryBegin(), isFalse);
    guard.reset();
    expect(guard.tryBegin(), isTrue);
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

  test('complete contract is POST /vot/complete JSON', () {
    expect(ApiEndpoints.votComplete, '/vot/complete');
    expect(ApiEndpoints.votSession(7), '/vot/7');
    expect(ApiEndpoints.votComplete, isNot(ApiEndpoints.votSession(7)));
    expect(
      VotFlow.completeRequestBody(7),
      <String, Object>{
        'daily_medication_id': 7,
        'drinking_verified': true,
      },
    );
  });

  test('405 is handled as error not success', () {
    final ApiException error = ApiException.fromDioException(
      DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(
          path: ApiEndpoints.votComplete,
          method: 'POST',
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: ApiEndpoints.votComplete),
          statusCode: 405,
          data: <String, dynamic>{'detail': 'Method Not Allowed'},
        ),
      ),
    );

    expect(error.statusCode, 405);
    expect(error.message, ApiException.methodNotAllowedMessage);
    expect(
      VotFlow.afterComplete(serverVerified: false),
      VerificationState.completing,
    );
    expect(
      VotFlow.retryTarget(
        state: VerificationState.completing,
        phaseError: true,
      ),
      VotRetryTarget.complete,
    );
  });

  test('drinking timeout stays on drinking and retries drinking only', () {
    expect(
      VotFlow.afterDrinkingTimeout(),
      VerificationState.drinking,
    );
    expect(
      VotFlow.afterDrinkingTimeout(),
      isNot(VerificationState.ready),
    );
    expect(
      VotFlow.afterDrinkingRetry(),
      VerificationState.drinking,
    );
    expect(
      VotFlow.retryTarget(
        state: VerificationState.drinking,
        phaseError: true,
      ),
      VotRetryTarget.drinking,
    );
    expect(
      VotFlow.retryTarget(
        state: VerificationState.drinking,
        phaseError: true,
      ),
      isNot(VotRetryTarget.face),
    );
    expect(
      VotFlow.retryTarget(
        state: VerificationState.drinking,
        phaseError: true,
      ),
      isNot(VotRetryTarget.medicine),
    );
    expect(DrinkingSequenceConfig.timeoutMessage, contains('coba lagi'));
  });

  test('screen stays awake during VOT and off when idle or completed', () async {
    expect(VerificationState.ready.keepScreenAwake, isFalse);
    expect(VerificationState.completed.keepScreenAwake, isFalse);
    expect(VerificationState.starting.keepScreenAwake, isTrue);
    expect(VerificationState.drinking.keepScreenAwake, isTrue);
    expect(VerificationState.completing.keepScreenAwake, isTrue);

    final List<String> calls = <String>[];
    final VotScreenAwake awake = VotScreenAwake(
      invoke: (String method) async => calls.add(method),
    );

    await awake.sync(keepOn: true);
    await awake.sync(keepOn: true);
    await awake.sync(keepOn: false);
    expect(calls, <String>['enable', 'disable']);
    expect(awake.isEnabled, isFalse);
  });

  test('video notification resume uses GET /vot/{id} not POST /vot/start', () {
    expect(ApiEndpoints.votSession(19), '/vot/19');
    expect(ApiEndpoints.votStart, '/vot/start');
    expect(ApiEndpoints.votSession(19), isNot(contains('start')));
  });

  test('complete notification does not change final success rule', () {
    expect(
      VotFlow.isServerVerified(status: 'verified', votStep: 'verified'),
      isTrue,
    );
    expect(
      VotFlow.afterComplete(serverVerified: true),
      VerificationState.completed,
    );
    expect(
      VotFlow.afterSession(votStep: 'verified'),
      VerificationState.completed,
    );
  });
}
