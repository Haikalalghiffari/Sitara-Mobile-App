import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_treatment.dart';

/// Kartu runtutan harian.
///
/// Backend belum memiliki data verifikasi minum obat. Sementara ini, angka
/// yang ditampilkan adalah `elapsedDays` dari [TreatmentProgress] — rumus
/// tanggal yang sama dengan [ProgressTimelineCard], dihitung dari
/// `therapy_start_date` sampai hari ini. Bukan streak verifikasi aktual.
///
// TODO: Saat backend sudah memiliki data actual medication adherence /
// verified medication intake dari AI VOT atau medication verification, ganti
// streak berbasis kalender ini dengan runtutan hari yang benar-benar
// terverifikasi. Jangan menghitung streak dari therapy_start_date lagi.
class ProgressStreakCard extends StatelessWidget {
  const ProgressStreakCard({
    super.key,
    this.progress,
    this.errorMessage,
  });

  /// Perhitungan waktu terapi yang sama dengan [ProgressTimelineCard].
  final TreatmentProgress? progress;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final int? elapsedDays = progress?.elapsedDays;
    final bool hasStreak = elapsedDays != null && elapsedDays > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.card,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.health_and_safety,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 22,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    "RUNTUTAN HARIAN",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                hasStreak ? "$elapsedDays Hari" : "Belum tersedia",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 22),

              Text(
                hasStreak
                    ? "Anda telah mempertahankan rutinitas pengobatan dengan baik."
                    : (errorMessage ??
                        "Runtutan harian akan muncul setelah data pengobatan tersedia."),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.7,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
