import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/camera_status.dart';
import '../models/verification_state.dart';
import 'camera_frame_guide.dart';
import 'medicine_detection_area.dart';
import 'verification_status.dart';

/// Area kamera beserta seluruh overlay panduan.
///
/// Menampilkan live feed dari kamera perangkat. Overlay panduan hanya
/// ditampilkan ketika kamera sudah benar-benar siap agar tidak menutupi
/// pesan status atau error.
class VerificationCameraView extends StatelessWidget {
  const VerificationCameraView({
    super.key,
    required this.state,
    required this.cameraStatus,
    this.controller,
    this.onRetryCamera,
  });

  final VerificationState state;
  final CameraStatus cameraStatus;
  final CameraController? controller;
  final VoidCallback? onRetryCamera;

  bool get _isPreviewVisible {
    final camera = controller;
    return cameraStatus.isReady &&
        camera != null &&
        camera.value.isInitialized;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.cardLarge,
      child: ColoredBox(
        color: AppColors.inverseSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isPreviewVisible)
              _CameraPreviewLayer(controller: controller!)
            else
              _CameraStatusLayer(
                status: cameraStatus,
                onRetry: onRetryCamera,
              ),

            if (_isPreviewVisible) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CameraFrameGuide(
                  color: state.isProcessing
                      ? AppColors.primaryLight
                      : AppColors.primaryLight.withValues(alpha: 0.7),
                ),
              ),

              Align(
                alignment: const Alignment(0, 0.45),
                child: MedicineDetectionArea(
                  highlighted: state == VerificationState.detectingMedicine,
                ),
              ),

              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: _InstructionBanner(state: state),
              ),
            ],

            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VerificationStepIndicator(state: state),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: VerificationStatusPill(
                        state: state,
                        overrideLabel: cameraStatus.isReady
                            ? null
                            : cameraStatus.statusLabel,
                        overrideColor: cameraStatus.isReady
                            ? null
                            : cameraStatusColor(cameraStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview kamera.
///
/// Ukuran preview disesuaikan agar mengisi area tanpa terdistorsi.
class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return const ColoredBox(color: AppColors.inverseSurface);
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          // previewSize dilaporkan dalam orientasi landscape,
          // jadi sisinya ditukar untuk tampilan portrait.
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// Tampilan ketika kamera sedang disiapkan atau gagal digunakan.
class _CameraStatusLayer extends StatelessWidget {
  const _CameraStatusLayer({required this.status, this.onRetry});

  final CameraStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy =
        status == CameraStatus.initializing || status == CameraStatus.ready;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.inverseSurface,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: AppSpacing.iconLg,
                  height: AppSpacing.iconLg,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  status == CameraStatus.permissionDenied
                      ? Icons.no_photography_outlined
                      : Icons.videocam_off_outlined,
                  size: AppSpacing.iconXl,
                  color: Colors.white.withValues(alpha: 0.6),
                ),

              const SizedBox(height: AppSpacing.lg),

              Text(
                status.statusLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                status.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),

              if (!isBusy) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: AppSpacing.iconMd,
                  ),
                  label: const Text("Coba Lagi"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.state});

  final VerificationState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        state.instruction,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
