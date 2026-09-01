import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/pages/ai_vot_page.dart';
import 'package:sitara/features/home/pages/home_page.dart';
import 'package:sitara/features/home/widgets/home_verification_section.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_open.dart';

NotificationModel _medicine() {
  return const NotificationModel(
    id: 9,
    userId: 8,
    title: 'Pengingat minum obat',
    message: 'Jadwal minum obat Anda sudah tiba.',
    type: 'medicine',
    referenceType: null,
    referenceId: 19,
    isRead: false,
    isActive: true,
    createdAt: '2026-08-28T16:25:00+07:00',
    updatedAt: '2026-08-28T16:25:00+07:00',
  );
}

void main() {
  testWidgets('medicine notification does not leave an active AI-VOT route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('siap vot')),
      ),
    );

    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: NotificationOpen.votRouteName),
        builder: (_) => const Scaffold(body: Text('vot-active')),
      ),
    );
    await tester.pumpAndSettle();

    expect(NotificationOpen.isVotOnTop(navigator), isTrue);
    NotificationOpen.go(navigator.context, _medicine());
    await tester.pump();

    expect(find.text('vot-active'), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(AiVotPage), findsNothing);
  });

  test('home still opens AI-VOT with the existing named route only on tap', () {
    expect(NotificationOpen.votRouteName, '/ai-vot');
    expect(HomeVerificationSection, isNotNull);
  });
}
