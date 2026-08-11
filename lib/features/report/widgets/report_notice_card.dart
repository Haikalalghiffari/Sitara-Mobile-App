import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ReportNoticeCard extends StatelessWidget {
  const ReportNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: AppRadius.card,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 4,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [

                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      "Notice",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // TODO: Kembalikan penjelasan alur peninjauan oleh tenaga
                // kesehatan setelah POST /complaints dapat diakses role
                // patient. Sebelum itu, kartu ini tidak boleh menjanjikan
                // laporan terkirim ke Puskesmas.
                Text(
                  "Pengiriman laporan melalui aplikasi belum tersedia untuk akun pasien. Sampaikan keluhan Anda langsung kepada tenaga kesehatan di Puskesmas.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}