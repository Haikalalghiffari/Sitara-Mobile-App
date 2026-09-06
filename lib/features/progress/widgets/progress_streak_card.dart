import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/patient_progress.dart';

/// Kartu runtutan harian.
///
/// Angkanya adalah `streak_days` dari `GET /medications/progress`. Bukan
/// `elapsedDays`, bukan lama terapi, dan bukan hitungan dari
/// `therapy_start_date`. Aplikasi tidak menambah maupun mereset streak.
class ProgressStreakCard extends StatelessWidget {
  const ProgressStreakCard({
    super.key,
    this.patientProgress,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Ringkasan kepatuhan dari backend. Null selama memuat atau saat gagal.
  final PatientProgress? patientProgress;

  final bool isLoading;

  final String? errorMessage;

  static const String loadingMessage = 'Memuat runtutan harian...';

  static const String emptyStreakMessage =
      'Belum ada runtutan hari terverifikasi.';

  @override
  Widget build(BuildContext context) {
    final int? streakDays = patientProgress?.streakDays;
    final bool hasStreak = streakDays != null;

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
                hasStreak ? "$streakDays Hari" : "Belum tersedia",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 22),

              Text(
                _description(streakDays),
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

  String _description(int? streakDays) {
    if (streakDays == null) {
      if (isLoading) return loadingMessage;
      if (errorMessage != null) return errorMessage!;
      return "Runtutan harian akan muncul setelah data kepatuhan tersedia.";
    }

    if (streakDays <= 0) return emptyStreakMessage;
    return "Anda telah mempertahankan rutinitas pengobatan dengan baik.";
  }
}
