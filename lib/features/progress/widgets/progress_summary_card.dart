import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/patient_progress.dart';

/// Kartu kepatuhan keseluruhan.
///
/// Seluruh angka berasal dari `GET /medications/progress`. Aplikasi tidak
/// menghitung ulang kepatuhan, tidak membagi successful dengan total, dan
/// tidak memakai tanggal terapi sebagai kepatuhan. Bila backend mengirim
/// `adherence_percentage` null, kartu menampilkan keadaan belum ada data,
/// bukan 100%.
class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
    this.patientProgress,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Ringkasan kepatuhan dari backend. Null selama memuat atau saat gagal.
  final PatientProgress? patientProgress;

  final bool isLoading;

  final String? errorMessage;

  static const String noAdherenceMessage = 'Belum ada data kepatuhan';

  static const String loadingMessage = 'Memuat data kepatuhan...';

  @override
  Widget build(BuildContext context) {
    final PatientProgress? summary = patientProgress;
    final double? adherence = summary?.adherenceFraction;
    final String? adherenceLabel = summary?.adherenceLabel;

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
                      adherenceLabel ?? "—",
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
            _description(summary),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),

          // Rincian occurrence ditampilkan apa adanya dari backend, tanpa
          // dijumlahkan atau dibagi di aplikasi.
          if (summary != null) ...[
            const SizedBox(height: 20),

            _breakdownRow(
              context,
              label: "Terverifikasi",
              value: summary.successfulOccurrences,
            ),

            _breakdownRow(
              context,
              label: "Gagal",
              value: summary.failedOccurrences,
            ),

            _breakdownRow(
              context,
              label: "Menunggu pemeriksaan",
              value: summary.pendingReviewOccurrences,
            ),

            _breakdownRow(
              context,
              label: "Sudah jatuh tempo",
              value: summary.finalDueOccurrences,
            ),
          ],
        ],
      ),
    );
  }

  /// Teks penjelas mengikuti keadaan data, tanpa penilaian karangan.
  String _description(PatientProgress? summary) {
    if (summary == null) {
      if (isLoading) return loadingMessage;
      if (errorMessage != null) return errorMessage!;
      return "Data kepatuhan belum tersedia. Informasi perkembangan pengobatan akan muncul setelah data pengobatan tersedia.";
    }

    if (!summary.hasAdherence) {
      return "$noAdherenceMessage. Kepatuhan akan muncul setelah ada jadwal minum obat yang jatuh tempo.";
    }

    return "${summary.successfulOccurrences} dari "
        "${summary.finalDueOccurrences} jadwal yang sudah jatuh tempo "
        "terverifikasi.";
  }

  Widget _breakdownRow(
    BuildContext context, {
    required String label,
    required int value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),

          Text(
            "$value",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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