import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.infoContainer,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.component,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privasi & Keamanan Data",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Semua informasi pribadi dan data kesehatan Anda "
                  "dilindungi menggunakan standar keamanan yang tinggi. "
                  "Data hanya dapat diakses oleh tenaga kesehatan yang "
                  "berwenang sesuai dengan kebijakan privasi SITARA Health.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.success,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      "Data terenkripsi & aman",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}