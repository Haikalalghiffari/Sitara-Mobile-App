import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../report/pages/report_page.dart';

class HomeReportButton extends StatelessWidget {
  const HomeReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.card,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPaddingSmall),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_information,
                color: AppColors.error,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lapor Keluhan",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Laporkan efek samping atau kendala selama pengobatan.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}