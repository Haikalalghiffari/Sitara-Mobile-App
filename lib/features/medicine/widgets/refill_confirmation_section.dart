import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class RefillConfirmationSection extends StatelessWidget {
  const RefillConfirmationSection({super.key});

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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: false,
            onChanged: (_) {},
            activeColor: AppColors.primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                  children: const [
                    TextSpan(
                      text:
                          "Saya menyatakan bahwa informasi yang saya berikan benar dan dapat dipertanggungjawabkan. ",
                    ),
                    TextSpan(
                      text:
                          "Saya memahami bahwa permintaan ini akan diverifikasi oleh petugas kesehatan sebelum disetujui.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}