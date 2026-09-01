import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

import '../../features/notification/pages/notification_page.dart';
import '../../features/notification/utils/notification_inbox_scope.dart';
import '../../features/notification/widgets/notification_unread_badge.dart';

class SitaraAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SitaraAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final inbox = NotificationInboxScope.maybeOf(context);

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,

      titleSpacing: AppSpacing.screenHorizontal,

      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Text(
            "SITARA Health",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.screenHorizontal,
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  splashRadius: 22,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.onSurface,
                  ),
                ),
                if (inbox != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: NotificationBellBadge(inbox: inbox),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
