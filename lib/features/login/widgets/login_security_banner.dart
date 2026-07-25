import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Banner informasi keamanan data medis.
class LoginSecurityBanner extends StatelessWidget {
  const LoginSecurityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.loginSecuritySurface,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.healthPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.healthPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Data anda dilindungi oleh enkripsi standar medis.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.healthPrimaryDark,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
