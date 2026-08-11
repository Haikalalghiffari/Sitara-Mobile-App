import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Keterangan privasi dan status fitur di bawah tombol utama.
class VerificationInfo extends StatelessWidget {
  const VerificationInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: AppSpacing.iconSm,
              color: AppColors.textSecondary,
            ),

            const SizedBox(width: AppSpacing.sm),

            Flexible(
              child: Text(
                "Video digunakan untuk validasi pengobatan.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          "Model AI belum terhubung dan hasil verifikasi belum dapat dikirim ke petugas.",
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
