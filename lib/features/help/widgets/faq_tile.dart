import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const FAQTile({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: 6,
          ),

          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            0,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
          ),

          collapsedIconColor: AppColors.primary,
          iconColor: AppColors.primary,

          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.primary,
            ),
          ),

          title: Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          children: [

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Masih membutuhkan bantuan? Hubungi tenaga kesehatan melalui menu Chat SITARA.",
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
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