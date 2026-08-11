import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import 'profile_notice.dart';

class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            "Profil",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),

          const Spacer(),

          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              splashRadius: 22,
              onPressed: () => showProfileNotice(
                context,
                profileEditUnavailableMessage,
              ),
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}