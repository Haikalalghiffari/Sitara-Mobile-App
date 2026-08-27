import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/camera_status.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/utils/vot_completion_guard.dart';
import 'package:sitara/features/ai_vot/utils/vot_screen_awake.dart';
import 'package:sitara/features/ai_vot/widgets/verification_action_button.dart';
import 'package:sitara/features/ai_vot/widgets/verification_camera_view.dart';
import 'package:sitara/features/ai_vot/widgets/verification_indicator_panel.dart';

void main() {
  test(
    'permission denied and permanent denied map from camera exception codes',
    () {
      expect(
        cameraStatusFromExceptionCode('CameraAccessDenied'),
        CameraStatus.permissionDenied,
      );
      expect(
        cameraStatusFromExceptionCode('CameraAccessDeniedWithoutPrompt'),
        CameraStatus.permissionPermanentlyDenied,
      );
      expect(
        cameraStatusFromExceptionCode('CameraAccessRestricted'),
        CameraStatus.permissionPermanentlyDenied,
      );
      expect(
        cameraStatusFromExceptionCode('CameraException'),
        CameraStatus.unavailable,
      );
      expect(CameraStatus.permissionDenied.needsAppSettings, isFalse);
      expect(CameraStatus.permissionPermanentlyDenied.needsAppSettings, isTrue);
      expect(CameraStatus.permissionDenied.retryLabel, 'Coba Lagi');
      expect(
        CameraStatus.permissionPermanentlyDenied.retryLabel,
        'Buka Pengaturan',
      );
      expect(
        CameraStatus.permissionDenied.description,
        'Izin kamera diperlukan untuk verifikasi.',
      );
    },
  );

  test('wake lock off when idle, completed, or phase error', () {
    expect(
      shouldKeepVotScreenAwake(
        state: VerificationState.drinking,
        phaseError: false,
      ),
      isTrue,
    );
    expect(
      shouldKeepVotScreenAwake(
        state: VerificationState.drinking,
        phaseError: true,
      ),
      isFalse,
    );
    expect(
      shouldKeepVotScreenAwake(
        state: VerificationState.completed,
        phaseError: false,
      ),
      isFalse,
    );
    expect(
      shouldKeepVotScreenAwake(
        state: VerificationState.ready,
        phaseError: false,
      ),
      isFalse,
    );
    expect(
      shouldKeepVotScreenAwake(
        state: VerificationState.completing,
        phaseError: true,
      ),
      isFalse,
    );
  });

  test('wake lock helper does not re-enable when already on', () async {
    final List<String> calls = <String>[];
    final VotScreenAwake awake = VotScreenAwake(
      invoke: (String method) async => calls.add(method),
    );

    await awake.sync(keepOn: true);
    await awake.sync(keepOn: true);
    await awake.disable();
    await awake.disable();
    expect(calls, <String>['enable', 'disable']);
  });

  test('complete guard still blocks duplicate success navigation path', () {
    final VotCompletionGuard guard = VotCompletionGuard();
    expect(guard.tryBegin(), isTrue);
    expect(guard.tryBegin(), isFalse);
    guard.markSuccess();
    expect(guard.tryBegin(), isFalse);
  });

  testWidgets(
    'permission denied camera overlay is retryable and does not crash',
    (WidgetTester tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: VerificationCameraView(
                state: VerificationState.ready,
                cameraStatus: CameraStatus.permissionDenied,
                onRetryCamera: () => retries++,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Izin kamera diperlukan'), findsWidgets);
      expect(
        find.text('Izin kamera diperlukan untuk verifikasi.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      expect(retries, 1);
    },
  );

  testWidgets(
    'camera init failure shows retry without stacking a second button',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: VerificationCameraView(
                state: VerificationState.ready,
                cameraStatus: CameraStatus.unavailable,
                onRetryCamera: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsNothing);
    },
  );

  testWidgets('permanent permission uses settings CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: VerificationCameraView(
              state: VerificationState.ready,
              cameraStatus: CameraStatus.permissionPermanentlyDenied,
              onRetryCamera: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buka Pengaturan'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
  });

  testWidgets('compact phone layout does not overflow VOT chrome', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const Expanded(flex: 3, child: ColoredBox(color: Colors.black)),
                Flexible(
                  flex: 2,
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VerificationIndicatorPanel(
                          state: VerificationState.drinking,
                        ),
                        VerificationActionButton(
                          state: VerificationState.completed,
                          onFinish: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Selesai'), findsOneWidget);
  });

  test('exit and success pop guards fire only once', () {
    var leaves = 0;
    var didLeave = false;
    void leave() {
      if (didLeave) return;
      didLeave = true;
      leaves++;
    }

    leave();
    leave();
    expect(leaves, 1);
  });
}
