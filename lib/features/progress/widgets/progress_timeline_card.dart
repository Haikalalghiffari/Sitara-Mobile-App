import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan minggu dan persentase
/// contoh.
///
// TODO: Integrasikan timeline setelah backend menyediakan endpoint treatment
// yang dapat diakses role patient. Minggu ke-n, total minggu, dan persentase
// dihitung dari therapy_start_date serta therapy_end_date pada
// TreatmentResponse, sedangkan GET /treatments memakai require_nakes.
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

          Text(
            "Belum tersedia",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 12,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Label "Bulan 1 / Sekarang / Bulan 6" dihapus karena mengandaikan
          // masa pengobatan 6 bulan, padahal durasi sebenarnya hanya diketahui
          // dari therapy_start_date dan therapy_end_date milik pasien.
          Text(
            "Informasi perkembangan pengobatan akan muncul setelah data pengobatan tersedia.",
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