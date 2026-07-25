import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class NotificationSettingsHeader extends StatelessWidget {
  const NotificationSettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            "Pengaturan Notifikasi",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}