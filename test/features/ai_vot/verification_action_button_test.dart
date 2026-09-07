import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/verification_state.dart';
import 'package:sitara/features/ai_vot/widgets/verification_action_button.dart';

void main() {
  testWidgets('drinking menampilkan Selesai Minum, bukan Coba Lagi', (
    WidgetTester tester,
  ) async {
    var stopped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerificationActionButton(
            state: VerificationState.drinking,
            onStopDrinking: () => stopped = true,
          ),
        ),
      ),
    );

    expect(find.text('Selesai Minum'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsNothing);
    await tester.tap(find.text('Selesai Minum'));
    expect(stopped, isTrue);
  });

  testWidgets('drinking video ready menampilkan Video Tersimpan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerificationActionButton(
            state: VerificationState.drinking,
            drinkingVideoReady: true,
          ),
        ),
      ),
    );

    expect(find.text('Video Tersimpan'), findsOneWidget);
    expect(find.text('Selesai Minum'), findsNothing);
  });
}
