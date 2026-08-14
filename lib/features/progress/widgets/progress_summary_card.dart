import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_treatment.dart';

/// Kartu kepatuhan keseluruhan.
///
/// Backend belum menyediakan data dosis yang diminum atau terverifikasi.
/// Sementara ini, bila terapi sudah berjalan, nilai yang ditampilkan adalah
/// 100% sebagai **asumsi sementara** bahwa pasien patuh setiap hari sejak
/// `therapy_start_date`. Bukan hasil AI VOT, bukan hasil verifikasi dosis.
///
// TODO: Saat backend sudah memiliki data actual medication adherence /
// verified medication intake dari AI VOT atau medication verification, ganti
// asumsi 100% ini dengan data aktual. Jangan menghitung kepatuhan dari
// therapy_start_date / therapy_end_date lagi.
class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
    this.progress,
    this.errorMessage,
  });

  /// Perhitungan waktu terapi yang sama dengan [ProgressTimelineCard].
  final TreatmentProgress? progress;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final double? adherence = progress?.assumedAdherence;

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
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [

          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _ProgressPainter(adherence ?? 0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      adherence == null
                          ? "—"
                          : "${(adherence * 100).round()}%",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Kepatuhan",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            "Kepatuhan Keseluruhan",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 14),

          Text(
            adherence == null
                ? (errorMessage ??
                    "Data kepatuhan belum tersedia. Informasi perkembangan pengobatan akan muncul setelah data pengobatan tersedia.")
                : "Kepatuhan pengobatan Anda saat ini sangat baik.",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;

  _ProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - strokeWidth;

    final backgroundPaint = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}