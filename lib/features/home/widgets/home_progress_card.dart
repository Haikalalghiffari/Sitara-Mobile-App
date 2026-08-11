import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan angka contoh.
///
// TODO: Integrasikan Treatment API setelah backend menyediakan endpoint
// treatment yang dapat diakses oleh role patient. Saat ini satu-satunya
// endpoint treatment adalah GET /treatments yang memakai require_nakes,
// sehingga akun pasien tidak boleh memanggilnya. Setelah endpoint per
// pasien tersedia, hari ke-n, total hari, dan persentase dihitung dari
// therapy_start_date serta therapy_end_date pada TreatmentResponse.
class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({super.key});

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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "YOUR PROGRESS",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: Text(
                  "Belum ada data pengobatan",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 10,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.progressFill,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Data masa pengobatan belum tersedia. Informasi ini akan muncul setelah petugas kesehatan melengkapi data pengobatanmu.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}