import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class NotificationSectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;

  const NotificationSectionTitle({
    super.key,
    required this.title,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        if (actionText != null)
          TextButton(
            onPressed: () {
              // TODO
              // Tandai semua sudah dibaca
            },
            child: Text(
              actionText!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}