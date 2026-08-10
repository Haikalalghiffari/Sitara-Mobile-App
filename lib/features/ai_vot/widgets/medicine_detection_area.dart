import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Area khusus tempat pasien memperlihatkan obat.
///
/// Nanti area ini menjadi acuan posisi bagi medicine detection.
class MedicineDetectionArea extends StatelessWidget {
  const MedicineDetectionArea({
    super.key,
    this.label = "Perlihatkan obat",
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? AppColors.primaryLight
        : Colors.white.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 138,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlighted ? 0.12 : 0.06),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medication_outlined,
            size: AppSpacing.iconLg,
            color: highlighted
                ? AppColors.primaryLight
                : Colors.white.withValues(alpha: 0.7),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
