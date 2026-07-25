import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Pembatas dengan teks di tengah.
class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.outlineVariantLight, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.outlineVariantLight, height: 1),
        ),
      ],
    );
  }
}
