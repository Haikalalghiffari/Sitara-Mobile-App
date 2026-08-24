import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/verification_state.dart';

/// Status tiap komponen pemeriksaan.
enum _IndicatorStatus { pending, active, done, failed }

/// Panel putih berisi indikator Wajah, Obat, dan Keaslian.
///
/// Status di sini mengikuti state UI, bukan hasil deteksi AI.
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
              caption: _faceCaption(state),
            ),
          ),
          Expanded(
            child: _IndicatorItem(
              icon: Icons.medication_outlined,
              label: "Obat",
              status: _medicineStatus(state),
              caption: _medicineCaption(state),
            ),
          ),
          Expanded(
            child: _IndicatorItem(
              icon: Icons.verified_user_outlined,
              label: "Keaslian",
              status: _authenticityStatus(state),
              caption: _authenticityCaption(state),
            ),
          ),
        ],
      ),
    );
  }

  static _IndicatorStatus _faceStatus(VerificationState state) {
    return switch (state) {
      VerificationState.ready => _IndicatorStatus.pending,
      VerificationState.detectingFace => _IndicatorStatus.active,
      VerificationState.failed => _IndicatorStatus.failed,
      VerificationState.faceVerified ||
      VerificationState.detectingMedicine ||
      VerificationState.analyzingPose ||
      VerificationState.verifying ||
      VerificationState.success =>
        _IndicatorStatus.done,
    };
  }

  static String _faceCaption(VerificationState state) {
    return switch (state) {
      VerificationState.detectingFace => "Memeriksa",
      VerificationState.failed => "Tidak cocok",
      VerificationState.faceVerified ||
      VerificationState.detectingMedicine ||
      VerificationState.analyzingPose ||
      VerificationState.verifying ||
      VerificationState.success =>
        "Terverifikasi",
      VerificationState.ready => "Menunggu",
    };
  }

  static _IndicatorStatus _medicineStatus(VerificationState state) {
    return switch (state) {
      VerificationState.ready ||
      VerificationState.failed ||
      VerificationState.detectingFace ||
      VerificationState.faceVerified =>
        _IndicatorStatus.pending,
      VerificationState.detectingMedicine => _IndicatorStatus.active,
      VerificationState.analyzingPose ||
      VerificationState.verifying ||
      VerificationState.success =>
        _IndicatorStatus.done,
    };
  }

  static String _medicineCaption(VerificationState state) {
    return switch (_medicineStatus(state)) {
      _IndicatorStatus.pending => "Menunggu",
      _IndicatorStatus.active => "Memeriksa",
      _IndicatorStatus.done => "Selesai",
      _IndicatorStatus.failed => "Gagal",
    };
  }

  static _IndicatorStatus _authenticityStatus(VerificationState state) {
    return switch (state) {
      VerificationState.ready ||
      VerificationState.failed ||
      VerificationState.detectingFace ||
      VerificationState.detectingMedicine ||
      VerificationState.faceVerified =>
        _IndicatorStatus.pending,
      VerificationState.analyzingPose ||
      VerificationState.verifying =>
        _IndicatorStatus.active,
      VerificationState.success => _IndicatorStatus.done,
    };
  }

  static String _authenticityCaption(VerificationState state) {
    return switch (_authenticityStatus(state)) {
      _IndicatorStatus.pending => "Menunggu",
      _IndicatorStatus.active => "Memeriksa",
      _IndicatorStatus.done => "Selesai",
      _IndicatorStatus.failed => "Gagal",
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
      _IndicatorStatus.done => (
          AppColors.successContainer,
          AppColors.success,
        ),
      _IndicatorStatus.failed => (
          AppColors.errorContainer,
          AppColors.error,
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            switch (status) {
              _IndicatorStatus.done => Icons.check_rounded,
              _IndicatorStatus.failed => Icons.close_rounded,
              _ => icon,
            },
            size: AppSpacing.iconMd,
            color: foreground,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),

        const SizedBox(height: 2),

        Text(
          caption,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
