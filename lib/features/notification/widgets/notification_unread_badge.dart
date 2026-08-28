import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../utils/notification_inbox.dart';

/// Badge merah pada ikon lonceng. Kosong jika unread = 0.
class NotificationUnreadBadge extends StatelessWidget {
  const NotificationUnreadBadge({
    super.key,
    required this.count,
  });

  final int count;

  static String labelFor(int count, {int max = 99}) {
    if (count <= 0) return '';
    if (count > max) return '$max+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final String label = labelFor(count);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class NotificationBellBadge extends StatelessWidget {
  const NotificationBellBadge({
    super.key,
    required this.inbox,
  });

  final NotificationInbox inbox;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: inbox,
      builder: (BuildContext context, _) {
        return NotificationUnreadBadge(count: inbox.unreadCount);
      },
    );
  }
}
