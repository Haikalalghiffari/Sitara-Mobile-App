import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Header atas: logo SITARA Health.
class LoginAppBar extends StatelessWidget {
  const LoginAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.healthPrimaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.healthPrimary,
              size: 20,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Text(
            'SITARA Health',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.healthPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}