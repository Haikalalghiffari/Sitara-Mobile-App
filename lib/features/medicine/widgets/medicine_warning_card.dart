import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class MedicineWarningCard extends StatelessWidget {
  const MedicineWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppRadius.card,
        border: const Border(
          left: BorderSide(
            color: AppColors.error,
            width: 5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 30,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              "Stok hampir habis, segera lakukan pengambilan!",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}