import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

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
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 25,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}