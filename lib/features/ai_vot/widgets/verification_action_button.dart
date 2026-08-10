import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/verification_state.dart';

/// Tombol utama halaman AI-VOT. Label dan aksinya mengikuti state.
class VerificationActionButton extends StatelessWidget {
  const VerificationActionButton({
    super.key,
    required this.state,
    this.onStart,
    this.onRetry,
    this.onFinish,
  });

  final VerificationState state;
  final VoidCallback? onStart;
  final VoidCallback? onRetry;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final (String label, IconData? icon, VoidCallback? onPressed) =
        switch (state) {
      VerificationState.ready => (
          "Mulai Verifikasi",
          Icons.camera_alt_rounded,
          onStart,
        ),
      VerificationState.success => (
          "Selesai",
          Icons.check_rounded,
          onFinish,
        ),
      VerificationState.failed => (
          "Coba Lagi",
          Icons.refresh_rounded,
          onRetry,
        ),
      _ => (state.statusLabel, null, null),
    };

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight + AppSpacing.xs,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: AppSpacing.iconMd)
            else
              const SizedBox(
                width: AppSpacing.iconMd,
                height: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),

            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
