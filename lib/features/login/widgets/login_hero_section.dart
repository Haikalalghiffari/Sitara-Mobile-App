import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Bagian hero: ikon shield, judul selamat datang, dan subtitle.
class LoginHeroSection extends StatelessWidget {
  const LoginHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.healthPrimary,
            borderRadius: AppRadius.xlRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.healthPrimary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Selamat Datang di SITARA',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.healthPrimaryDark,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Portal Kesehatan Terpadu untuk Pemulihan dan Kesejahteraan Anda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}
