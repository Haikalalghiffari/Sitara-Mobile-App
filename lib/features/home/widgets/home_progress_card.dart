import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../progress/models/my_treatment.dart';

/// Kartu progress masa pengobatan di Home.
///
/// Hari ke-n, total hari, dan persentase dihitung dari `therapy_start_date`
/// serta `therapy_end_date` pada `MyTreatmentResponse` dari
/// `GET /treatments/my`. Bila data belum ada, tampilan empty state
/// dipertahankan.
class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({
    super.key,
    this.treatment,
    this.errorMessage,
  });

  final MyTreatment? treatment;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final TreatmentProgress? progress = treatment?.progress;

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
                  progress == null
                      ? "Belum ada data pengobatan"
                      : "Day ${progress.elapsedDays} of ${progress.totalDays}",
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
              value: progress?.fraction ?? 0,
              minHeight: 10,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.progressFill,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _description(progress),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  String _description(TreatmentProgress? progress) {
    if (errorMessage != null && progress == null) {
      return errorMessage!;
    }

    if (progress == null) {
      return "Data masa pengobatan belum tersedia. Informasi ini akan muncul setelah petugas kesehatan melengkapi data pengobatanmu.";
    }

    return "Perjalananmu masih panjang, tetap semangat! Kamu telah menyelesaikan ${progress.percent}% dari total masa pengobatan.";
  }
}
