import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class HelpHeader extends StatelessWidget {
  const HelpHeader({super.key});

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
            "Bantuan",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        IconButton(
          onPressed: () {
            // TODO:
            // Navigasi ke halaman Notification
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 28,
          ),
        ),
      ],
    );
  }
}