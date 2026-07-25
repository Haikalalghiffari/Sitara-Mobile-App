import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class MedicineStockCard extends StatelessWidget {
  const MedicineStockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Stack(
        children: [

          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.medication,
              size: 120,
              color: AppColors.primary.withValues(alpha: .08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Stok Obat Saat Ini",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 14),

              RichText(
                text: TextSpan(
                  children: [

                    TextSpan(
                      text: "12",
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    TextSpan(
                      text: " / 60",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall,
                    ),

                    TextSpan(
                      text: " tablet",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: 0.20,
                  minHeight: 12,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Sisa stok: 4 hari lagi",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}