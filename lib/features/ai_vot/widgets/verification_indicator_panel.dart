import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/verification_state.dart';

enum _IndicatorStatus { pending, active, done }

class VerificationIndicatorPanel extends StatelessWidget {
  const VerificationIndicatorPanel({super.key, required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IndicatorItem(
              icon: Icons.face_retouching_natural_outlined,
              label: "Wajah",
              status: _faceStatus(state),
              caption: _caption(_faceStatus(state)),
            ),
          ),
          Expanded(
            child: _IndicatorItem(
              icon: Icons.medication_outlined,
              label: "Obat",
              status: _medicineStatus(state),
              caption: _caption(_medicineStatus(state)),
            ),
          ),
          Expanded(
            child: _IndicatorItem(
              icon: Icons.local_drink_outlined,
              label: "Minum",
              status: _drinkStatus(state),
              caption: _caption(_drinkStatus(state)),
            ),
          ),
        ],
      ),
    );
  }

  static String _caption(_IndicatorStatus status) {
    return switch (status) {
      _IndicatorStatus.pending => "Menunggu",
      _IndicatorStatus.active => "Proses",
      _IndicatorStatus.done => "Berhasil",
    };
  }

  static _IndicatorStatus _faceStatus(VerificationState state) {
    return switch (state) {
      VerificationState.ready ||
      VerificationState.starting => _IndicatorStatus.pending,
      VerificationState.faceVerifying => _IndicatorStatus.active,
      VerificationState.faceVerified ||
      VerificationState.medicineDetecting ||
      VerificationState.medicineMatched ||
      VerificationState.drinking ||
      VerificationState.completing ||
      VerificationState.completed ||
      VerificationState.needsReview => _IndicatorStatus.done,
    };
  }

  static _IndicatorStatus _medicineStatus(VerificationState state) {
    return switch (state) {
      VerificationState.ready ||
      VerificationState.starting ||
      VerificationState.faceVerifying ||
      VerificationState.faceVerified => _IndicatorStatus.pending,
      VerificationState.medicineDetecting => _IndicatorStatus.active,
      VerificationState.medicineMatched ||
      VerificationState.drinking ||
      VerificationState.completing ||
      VerificationState.completed ||
      VerificationState.needsReview => _IndicatorStatus.done,
    };
  }

  static _IndicatorStatus _drinkStatus(VerificationState state) {
    return switch (state) {
      VerificationState.drinking ||
      VerificationState.completing => _IndicatorStatus.active,
      VerificationState.completed ||
      VerificationState.needsReview => _IndicatorStatus.done,
      _ => _IndicatorStatus.pending,
    };
  }
}

class _IndicatorItem extends StatelessWidget {
  const _IndicatorItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final _IndicatorStatus status;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      _IndicatorStatus.pending => (
        AppColors.surfaceContainerHigh,
        AppColors.textDisabled,
      ),
      _IndicatorStatus.active => (
        AppColors.warningContainer,
        AppColors.warning,
      ),
      _IndicatorStatus.done => (AppColors.successContainer, AppColors.success),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(
            status == _IndicatorStatus.done ? Icons.check_rounded : icon,
            size: AppSpacing.iconMd,
            color: foreground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
