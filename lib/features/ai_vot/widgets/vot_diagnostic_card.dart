import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/drinking_analysis_result.dart';

/// Temporary diagnostic card to display real device test result of video analysis.
class VotDiagnosticCard extends StatelessWidget {
  const VotDiagnosticCard({
    super.key,
    required this.result,
    this.onClose,
  });

  final DrinkingAnalysisResult result;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = switch (result.level) {
      DrinkingConfidenceLevel.high => AppColors.success,
      DrinkingConfidenceLevel.medium => AppColors.warning,
      DrinkingConfidenceLevel.low => AppColors.error,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: badgeColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Badge and Close button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DEVICE TEST RESULT',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${result.confidenceScore.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: onClose,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Level & Status
          Row(
            children: [
              Text(
                result.statusLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• autoVerified: ${result.isAutoVerified}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Frame Metrics Grid
          _buildMetricRow('framesExtracted', '${result.framesExtracted}'),
          _buildMetricRow('handDetectedFrames', '${result.handDetectedFrames} / ${result.framesExtracted}'),
          _buildMetricRow('mouthDetectedFrames', '${result.faceDetectedFrames} / ${result.framesExtracted}'),
          _buildMetricRow('nearMouthFrames', '${result.nearMouthFrames}'),
          const SizedBox(height: 4),
          _buildMetricRow(
            'minimumDistance',
            result.minDistance != null ? result.minDistance!.toStringAsFixed(3) : '-',
          ),
          _buildMetricRow(
            'maximumDistance',
            result.maxDistance != null ? result.maxDistance!.toStringAsFixed(3) : '-',
          ),
          const Divider(height: 16),

          // Sequence Status
          const Text(
            'SEQUENCE PROGRESSION:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepBadge('FAR', result.farDetected),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.textSecondary),
              _buildStepBadge('APPROACH', result.approachDetected),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.textSecondary),
              _buildStepBadge('NEAR', result.nearMouthDetected),
              const Icon(Icons.arrow_forward, size: 12, color: AppColors.textSecondary),
              _buildStepBadge('WITHDRAW', result.withdrawDetected),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'sequenceCompleted',
            result.sequenceCompleted ? 'YES (Valid)' : 'NO (Incomplete)',
            valueColor: result.sequenceCompleted ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge(String title, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.outlineVariant.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 10,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
