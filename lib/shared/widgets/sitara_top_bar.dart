import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../features/notification/utils/notification_inbox_scope.dart';
import '../../features/notification/widgets/notification_unread_badge.dart';

class SitaraTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onNotification;

  const SitaraTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    final inbox = NotificationInboxScope.maybeOf(context);

    return SizedBox(
      height: AppSpacing.appBarHeight,
      child: Row(
        children: [

          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onNotification,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    size: 25,
                    color: AppColors.primary,
                  ),
                  if (inbox != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: NotificationBellBadge(inbox: inbox),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}