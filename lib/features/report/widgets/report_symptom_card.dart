import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ReportSymptomCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool isDanger;

  const ReportSymptomCard({
    super.key,
    required this.title,
    required this.icon,
    this.selected = false,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isDanger ? AppColors.error : AppColors.primary;

    return InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPaddingSmall),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),

        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: 1.3,
          ),
        ),

        child: Row(
          children: [

            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outline,
                  width: 2,
                ),
              ),

              child: selected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}