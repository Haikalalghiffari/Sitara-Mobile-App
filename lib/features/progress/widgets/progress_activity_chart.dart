import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ProgressActivityChart extends StatelessWidget {
  const ProgressActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final bars = [
      45.0,
      70.0,
      55.0,
      85.0,
      95.0,
      65.0,
      100.0,
    ];

    final days = [
      "Sen",
      "Sel",
      "Rab",
      "Kam",
      "Jum",
      "Sab",
      "Min",
    ];

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

          Row(
            children: [

              Expanded(
                child: Text(
                  "Aktivitas Mingguan",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                "Tercatat",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 36),

          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                bars.length,
                (index) {
                  final active = index == 6;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 22,
                        height: bars[index],
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        days[index],
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: active
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}