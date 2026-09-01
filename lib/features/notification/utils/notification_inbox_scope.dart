import 'package:flutter/material.dart';

import 'notification_inbox.dart';

/// Menyediakan [NotificationInbox] ke widget di bawah [MaterialApp.builder].
class NotificationInboxScope extends InheritedNotifier<NotificationInbox> {
  const NotificationInboxScope({
    super.key,
    required NotificationInbox inbox,
    required super.child,
  }) : super(notifier: inbox);

  static NotificationInbox? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NotificationInboxScope>()
        ?.notifier;
  }
}
