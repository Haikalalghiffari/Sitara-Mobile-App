import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class HomeMedicationTimerCard extends StatelessWidget {
  const HomeMedicationTimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: AppRadius.cardLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "JADWAL MINUM OBAT BERIKUTNYA",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              "02 : 14 : 54",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [

              Icon(
                Icons.schedule,
                color: Colors.white70,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                "Hari Ini • 10.30 WIB",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}