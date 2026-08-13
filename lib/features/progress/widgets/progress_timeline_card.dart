import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_treatment.dart';

/// Kartu timeline masa pengobatan di Progress.
///
/// Minggu ke-n, total minggu, dan persentase dihitung dari
/// `therapy_start_date` serta `therapy_end_date` pada `MyTreatmentResponse`
/// dari `GET /treatments/my`. Bila data belum ada, tampilan empty state
/// dipertahankan.
class ProgressTimelineCard extends StatelessWidget {
  const ProgressTimelineCard({
    super.key,
    this.treatment,
    this.errorMessage,
  });

  final MyTreatment? treatment;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final TreatmentProgress? progress = treatment?.progress;
    final DateTime? start = treatment?.therapyStart;
    final DateTime? end = treatment?.therapyEnd;
    final int? monthSpan = (start != null && end != null)
        ? (end.year - start.year) * 12 + (end.month - start.month) + 1
        : null;

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

          if (progress == null)
            Text(
              "Belum tersedia",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          else
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
                    text: "${progress.elapsedWeeks}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: " dari ${progress.totalWeeks}",
                  ),
                ],
              ),
            ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress?.fraction ?? 0,
              minHeight: 12,
              backgroundColor: AppColors.progressTrack,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (progress == null)
            Text(
              errorMessage ??
                  "Informasi perkembangan pengobatan akan muncul setelah data pengobatan tersedia.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            )
          else ...[
            Text(
              "${progress.percent}% Selesai",
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
                      "Bulan ${monthSpan ?? 1}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
