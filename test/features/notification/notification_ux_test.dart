import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_client.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/services/notification_service.dart';
import 'package:sitara/features/notification/utils/notification_inbox.dart';
import 'package:sitara/features/notification/utils/notification_open.dart';
import 'package:sitara/features/notification/utils/notification_route_tracker.dart';
import 'package:sitara/features/notification/utils/notification_tap.dart';
import 'package:sitara/features/notification/widgets/notification_overlay_host.dart';
import 'package:sitara/features/notification/widgets/notification_unread_badge.dart';
import 'package:dio/dio.dart';

NotificationModel _item({
  required int id,
  String type = 'medicine',
  bool isRead = false,
  String title = 'Pengingat minum obat',
  String message = 'Jadwal minum obat Anda sudah tiba.',
  int? referenceId,
  String createdAt = '2026-08-28T16:25:00+07:00',
}) {
  return NotificationModel(
    id: id,
    userId: 8,
    title: title,
    message: message,
    type: type,
    referenceType: null,
    referenceId: referenceId,
    isRead: isRead,
    isActive: true,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

NotificationModel _asRead(NotificationModel item) {
  return NotificationModel(
    id: item.id,
    userId: item.userId,
    title: item.title,
    message: item.message,
    type: item.type,
    referenceType: item.referenceType,
    referenceId: item.referenceId,
    isRead: true,
    isActive: item.isActive,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  );
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(this.store)
      : super(apiClient: ApiClient(dio: Dio()));

  List<NotificationModel> store;
  int fetchCount = 0;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    fetchCount++;
    return List<NotificationModel>.of(store);
  }

  @override
  Future<NotificationModel> markAsRead(int id) async {
    store = store
        .map(
          (NotificationModel item) => item.id == id ? _asRead(item) : item,
        )
        .toList();
    return store.firstWhere((NotificationModel item) => item.id == id);
  }

  @override
  Future<List<NotificationModel>> markAllAsRead() async {
    store = store.map(_asRead).toList();
    return List<NotificationModel>.of(store);
  }
}

void main() {
  testWidgets('unread badge 0 is hidden', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationUnreadBadge(count: 0),
        ),
      ),
    );
    expect(find.byType(NotificationUnreadBadge), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(NotificationUnreadBadge.labelFor(0), isEmpty);
  });

  testWidgets('unread badge 1 is shown', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationUnreadBadge(count: 1),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(NotificationUnreadBadge.labelFor(12), '12');
    expect(NotificationUnreadBadge.labelFor(100), '99+');
  });

  test('unread badge follows mark-read on inbox state', () async {
    final _FakeNotificationService service = _FakeNotificationService(
      <NotificationModel>[
        _item(id: 1),
        _item(id: 2),
        _item(id: 3),
      ],
    );
    final NotificationInbox inbox = NotificationInbox(
      service: service,
      isAuthenticated: () async => true,
      pollInterval: const Duration(days: 1),
    );
    inbox.replaceAll(service.store);
    expect(inbox.unreadCount, 3);
    expect(inbox.unreadBadgeLabel(), '3');

    final bool marked = await inbox.markAsRead(1);
    expect(marked, isTrue);
    expect(inbox.unreadCount, 2);
    expect(inbox.unreadBadgeLabel(), '2');
    inbox.dispose();
  });

  test('mark-all-read clears badge', () async {
    final _FakeNotificationService service = _FakeNotificationService(
      <NotificationModel>[_item(id: 1), _item(id: 2)],
    );
    final NotificationInbox inbox = NotificationInbox(
      service: service,
      isAuthenticated: () async => true,
      pollInterval: const Duration(days: 1),
    );
    inbox.replaceAll(service.store);
    expect(inbox.unreadCount, 2);

    final bool marked = await inbox.markAllAsRead();
    expect(marked, isTrue);
    expect(inbox.unreadCount, 0);
    expect(inbox.unreadBadgeLabel(), isEmpty);
    inbox.dispose();
  });

  testWidgets('new notification shows popup once', (WidgetTester tester) async {
    final _FakeNotificationService service = _FakeNotificationService(
      <NotificationModel>[_item(id: 1)],
    );
    final NotificationInbox inbox = NotificationInbox(
      service: service,
      isAuthenticated: () async => true,
      pollInterval: const Duration(days: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationOverlayHost(
          inbox: inbox,
          navigatorKey: GlobalKey<NavigatorState>(),
          routeTracker: NotificationRouteTracker(),
          child: const Scaffold(body: Text('Halaman aktif')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Pengingat minum obat'), findsNothing);

    service.store = <NotificationModel>[
      _item(id: 1),
      _item(id: 2, title: 'Sudah waktunya minum obat'),
    ];
    await inbox.refresh();
    await tester.pump();
    expect(find.text('Sudah waktunya minum obat'), findsOneWidget);

    await inbox.refresh();
    await tester.pump();
    expect(find.text('Sudah waktunya minum obat'), findsOneWidget);
    expect(inbox.alreadyAnnounced(2), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    inbox.dispose();
  });

  test('popup tap medicine opens Home, not VOT', () {
    final NotificationModel item =
        _item(id: 9, type: 'medicine', referenceId: 19);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.home);
    expect(NotificationTap.opensVot(item), isFalse);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.dailyMedicationId(item), isNull);
    expect(NotificationOpen.votRouteName, '/ai-vot');
  });

  test('complaint tap still opens report history', () {
    final NotificationModel item =
        _item(id: 4, type: 'complaint', referenceId: 42);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.complaintHistory);
    expect(NotificationTap.complaintId(item), 42);
    expect(NotificationTap.opensVot(item), isFalse);
  });

  test('refill tap still opens refill history', () {
    final NotificationModel item =
        _item(id: 5, type: 'refill', referenceId: 7);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.refillHistory);
    expect(NotificationTap.refillId(item), 7);
    expect(NotificationTap.opensVot(item), isFalse);
  });

  test('video tap still opens existing VOT resume route', () {
    final NotificationModel item =
        _item(id: 6, type: 'video', referenceId: 19);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.votSession);
    expect(NotificationTap.dailyMedicationId(item), 19);
    expect(NotificationTap.startsNewVotSession(item), isFalse);
    expect(NotificationTap.opensVot(item), isTrue);
  });

  test('control tap still opens medicine control highlight', () {
    final NotificationModel item =
        _item(id: 7, type: 'control', referenceId: 8);
    expect(NotificationTap.targetOf(item), NotificationOpenTarget.controlSchedule);
    expect(NotificationTap.shouldNavigate(item), isTrue);
    expect(NotificationTap.opensVot(item), isFalse);
  });

  test('relative time display does not poll GET every second', () {
    final NotificationInbox inbox = NotificationInbox(
      service: _FakeNotificationService(<NotificationModel>[]),
      isAuthenticated: () async => true,
      pollInterval: const Duration(seconds: 45),
    );
    expect(inbox.pollInterval, const Duration(seconds: 45));
    expect(inbox.pollInterval.inSeconds, greaterThan(1));
    inbox.dispose();
  });
}
