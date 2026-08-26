import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/camera_status.dart';
import '../models/verification_state.dart';

/// Warna titik status sesuai state verifikasi.
Color verificationStatusColor(VerificationState state) {
  return switch (state) {
    VerificationState.ready => AppColors.primaryLight,
    VerificationState.faceVerified ||
    VerificationState.medicineMatched ||
    VerificationState.completed =>
      AppColors.success,
    _ => AppColors.warning,
  };
}

/// Warna titik status sesuai kondisi kamera.
Color cameraStatusColor(CameraStatus status) {
  return switch (status) {
    CameraStatus.ready => AppColors.primaryLight,
    CameraStatus.initializing => AppColors.warning,
    CameraStatus.permissionDenied || CameraStatus.unavailable =>
      AppColors.error,
  };
}

/// Pill status AI di sudut area kamera. Contoh: "● Sistem siap".
///
/// [overrideLabel] dan [overrideColor] dipakai ketika kamera belum siap,
/// sehingga pill menampilkan kondisi kamera lebih dulu.
class VerificationStatusPill extends StatelessWidget {
  const VerificationStatusPill({
    super.key,
    required this.state,
    this.overrideLabel,
    this.overrideColor,
  });

  final VerificationState state;
  final String? overrideLabel;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: overrideColor ?? verificationStatusColor(state),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Flexible(
            child: Text(
              overrideLabel ?? state.statusLabel,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indikator tahapan proses verifikasi. Contoh: "● ○ ○ ○".
class VerificationStepIndicator extends StatelessWidget {
  const VerificationStepIndicator({super.key, required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    final activeCount = state.activeStepCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(kVerificationStepCount, (index) {
          final isActive = index < activeCount;

          return Padding(
            padding: EdgeInsets.only(
              right: index == kVerificationStepCount - 1 ? 0 : AppSpacing.xs + 2,
            ),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryLight
                    : Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
