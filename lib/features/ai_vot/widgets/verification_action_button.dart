import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/verification_state.dart';

class VerificationActionButton extends StatelessWidget {
  const VerificationActionButton({
    super.key,
    required this.state,
    this.isBusy = false,
    this.hasPhaseError = false,
    this.onStart,
    this.onRetryFace,
    this.onDetectMedicine,
    this.onRetryMedicine,
    this.onRetryDrinking,
    this.onFinish,
  });

  final VerificationState state;
  final bool isBusy;
  final bool hasPhaseError;
  final VoidCallback? onStart;
  final VoidCallback? onRetryFace;
  final VoidCallback? onDetectMedicine;
  final VoidCallback? onRetryMedicine;
  final VoidCallback? onRetryDrinking;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final (String label, IconData? icon, VoidCallback? onPressed) =
        _resolve();

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight + AppSpacing.xs,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
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
            if (isBusy || icon == null)
              const SizedBox(
                width: AppSpacing.iconMd,
                height: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Flexible(
              child: Text(
                isBusy ? state.statusLabel : label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, IconData?, VoidCallback?) _resolve() {
    return switch (state) {
      VerificationState.ready => (
          "Mulai Verifikasi",
          Icons.camera_alt_rounded,
          onStart,
        ),
      VerificationState.faceVerifying => hasPhaseError
          ? ("Coba Lagi", Icons.refresh_rounded, onRetryFace)
          : (state.statusLabel, null, null),
      VerificationState.medicineDetecting => hasPhaseError
          ? ("Coba Lagi", Icons.refresh_rounded, onRetryMedicine)
          : (
              "Deteksi Obat",
              Icons.medication_outlined,
              onDetectMedicine,
            ),
      VerificationState.drinking => hasPhaseError
          ? ("Coba Lagi", Icons.refresh_rounded, onRetryDrinking)
          : (state.statusLabel, null, null),
      VerificationState.completed => (
          "Selesai",
          Icons.check_rounded,
          onFinish,
        ),
      _ => (state.statusLabel, null, null),
    };
  }
}
