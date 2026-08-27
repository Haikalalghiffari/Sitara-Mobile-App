import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/camera_status.dart';
import 'verification_status.dart';

/// Bingkai kamera lingkaran untuk pendaftaran wajah.
class RegisterFaceCameraFrame extends StatelessWidget {
  const RegisterFaceCameraFrame({
    super.key,
    required this.cameraStatus,
    this.controller,
    this.capturedImagePath,
    this.onRetryCamera,
  });

  final CameraStatus cameraStatus;
  final CameraController? controller;
  final String? capturedImagePath;
  final VoidCallback? onRetryCamera;

  bool get _isLivePreview {
    final CameraController? camera = controller;
    return capturedImagePath == null &&
        cameraStatus.isReady &&
        camera != null &&
        camera.value.isInitialized;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size = math.min(240, constraints.maxWidth);
        return Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: ColoredBox(
                      color: AppColors.inverseSurface,
                      child: _buildInner(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusPill(
              label: capturedImagePath != null
                  ? "Pratinjau foto"
                  : cameraStatus.isReady
                  ? "Siap mengambil foto"
                  : cameraStatus.statusLabel,
              color: capturedImagePath != null || cameraStatus.isReady
                  ? AppColors.primary
                  : cameraStatusColor(cameraStatus),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInner() {
    final String? path = capturedImagePath;
    if (path != null) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_isLivePreview) {
      return _LivePreview(controller: controller!);
    }

    return _StatusPlaceholder(status: cameraStatus, onRetry: onRetryCamera);
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final Size? previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const ColoredBox(color: AppColors.inverseSurface);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _StatusPlaceholder extends StatelessWidget {
  const _StatusPlaceholder({required this.status, this.onRetry});

  final CameraStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isBusy = status == CameraStatus.initializing;

    return ColoredBox(
      color: AppColors.primaryDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  status == CameraStatus.permissionDenied ||
                          status == CameraStatus.permissionPermanentlyDenied
                      ? Icons.no_photography_outlined
                      : Icons.videocam_off_outlined,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 36,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                status.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              if (!isBusy && onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    status.retryLabel,
                    style: const TextStyle(color: Colors.white),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
