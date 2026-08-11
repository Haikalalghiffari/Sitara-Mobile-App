import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan persentase contoh.
///
// TODO: Integrasikan kepatuhan setelah backend menyediakan endpoint yang
// dapat diakses role patient. Data kepatuhan berasal dari
// VideoVerificationResponse (status: pending/verified/rejected), tetapi
// response tersebut hanya memuat medicine_schedule_id, yang mengarah ke
// treatment_id, yang hanya bisa diperoleh dari GET /treatments
// (require_nakes).
class ProgressSummaryCard extends StatelessWidget {
  /// Bernilai null selama data kepatuhan belum tersedia dari backend.
  ///
  /// Sengaja nullable dan bukan 0, karena menampilkan "0%" berarti menyatakan
  /// pasien tidak pernah minum obat sama sekali.
  final double? progress;

  const ProgressSummaryCard({
    super.key,
    this.progress,
  });

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
              painter: _ProgressPainter(progress ?? 0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      progress == null
                          ? "—"
                          : "${(progress! * 100).round()}%",
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
            "Data kepatuhan belum tersedia. Informasi perkembangan pengobatan akan muncul setelah data pengobatan tersedia.",
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