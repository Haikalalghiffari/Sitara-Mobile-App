import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/notification/models/notification_model.dart';
import 'package:sitara/features/notification/utils/notification_read_ux.dart';
import 'package:sitara/features/notification/widgets/notification_header.dart';

NotificationModel _item({
  required int id,
  required bool isRead,
  String type = 'medicine',
}) {
  return NotificationModel(
    id: id,
    userId: 8,
    title: 'Judul $id',
    message: 'Isi',
    type: type,
    referenceType: null,
    referenceId: null,
    isRead: isRead,
    isActive: true,
    createdAt: '2026-08-26T10:00:00',
    updatedAt: '2026-08-26T10:00:00',
  );
}

void main() {
  test('unread count follows is_read from backend items', () {
    final List<NotificationModel> items = <NotificationModel>[
      _item(id: 1, isRead: false),
      _item(id: 2, isRead: true),
      _item(id: 3, isRead: false),
    ];
    expect(NotificationReadUx.unreadCount(items), 2);

    final NotificationModel read = _item(id: 1, isRead: true);
    final List<NotificationModel> updated =
        NotificationReadUx.applyRead(items, read);
    expect(NotificationReadUx.unreadCount(updated), 1);
    expect(updated.firstWhere((item) => item.id == 1).isRead, isTrue);
  });

  test('failed read payload does not mark item read', () {
    final List<NotificationModel> items = <NotificationModel>[
      _item(id: 1, isRead: false),
    ];
    final List<NotificationModel> same = NotificationReadUx.applyRead(
      items,
      _item(id: 1, isRead: false),
    );
    expect(same.first.isRead, isFalse);
    expect(NotificationReadUx.unreadCount(same), 1);
  });

  test('duplicate mark-read lock allows one in-flight request', () {
    final NotificationReadLock lock = NotificationReadLock();
    expect(lock.tryBegin(4), isTrue);
    expect(lock.tryBegin(4), isFalse);
    expect(lock.tryBegin(5), isTrue);
    lock.end(4);
    expect(lock.tryBegin(4), isTrue);
  });

  test('first fetch is not skipped while the spinner is already showing', () {
    const bool uiLoading = true;
    const bool inFlight = false;

    expect(uiLoading, isTrue);
    expect(
      NotificationReadUx.skipDuplicateFetch(inFlight: inFlight),
      isFalse,
    );
    expect(
      NotificationReadUx.skipDuplicateFetch(inFlight: true),
      isTrue,
    );
  });

  test('silent error keeps existing notification list', () {
    expect(
      NotificationReadUx.keepExistingOnError(
        silent: true,
        existing: <NotificationModel>[_item(id: 1, isRead: false)],
      ),
      isTrue,
    );
    expect(
      NotificationReadUx.keepExistingOnError(
        silent: true,
        existing: <NotificationModel>[],
      ),
      isFalse,
    );
  });

  testWidgets('header badge shows unread count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationHeader(
            onMarkAllRead: () {},
            onDeleteAll: () {},
            unreadCount: 3,
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
  });
}
