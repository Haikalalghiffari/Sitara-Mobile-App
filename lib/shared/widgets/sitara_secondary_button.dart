import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';

/// Tombol sekunder berbentuk pill (light surface + border).
class SitaraSecondaryButton extends StatelessWidget {
  const SitaraSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.huge + AppSpacing.xs,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.loginSecondarySurface,
          foregroundColor: AppColors.healthPrimary,
          elevation: 0,
          side: const BorderSide(color: AppColors.loginSecondaryBorder),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.healthPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        child: Text(label),
      ),
    );
  }
}
