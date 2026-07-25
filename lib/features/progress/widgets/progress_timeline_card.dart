import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ProgressTimelineCard extends StatelessWidget {
  const ProgressTimelineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Timeline Pengobatan",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 12),

          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              children: [
                const TextSpan(
                  text: "Minggu ke-",
                ),
                TextSpan(
                  text: "7",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: " dari 24",
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0.29,
              minHeight: 12,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "29% Selesai",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [

              Expanded(
                child: Text(
                  "Bulan 1",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              Expanded(
                child: Center(
                  child: Text(
                    "Sekarang",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Bulan 6",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}