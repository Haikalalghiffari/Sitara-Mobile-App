import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class NotificationCategoryTitle extends StatelessWidget {
  final String title;

  const NotificationCategoryTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
    );
  }
}