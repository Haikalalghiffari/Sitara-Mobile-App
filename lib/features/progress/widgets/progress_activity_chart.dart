import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_treatment.dart';

/// Ringkasan perjalanan waktu terapi dari `GET /treatments/my`.
///
/// Sengaja bukan grafik batang harian: backend tidak menyediakan riwayat minum
/// obat yang dapat diakses pasien, sehingga batang apa pun di sini akan
/// terbaca sebagai aktivitas minum obat yang tidak pernah tercatat.
///
/// Yang ditampilkan hanya tanggal mulai, lamanya terapi berjalan, perkiraan
/// selesai, fase, dan status. Tidak ada nilai kepatuhan.
class ProgressActivityChart extends StatelessWidget {
  const ProgressActivityChart({
    super.key,
    this.treatment,
    this.errorMessage,
  });

  final MyTreatment? treatment;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final MyTreatment? item = treatment;
    final String? statusLabel = item?.statusLabel;

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

          Row(
            children: [

              Expanded(
                child: Text(
                  "Perjalanan Pengobatan",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Penanda di kanan atas menampilkan status terapi dari backend,
              // menggantikan legenda "Tercatat" yang dahulu milik grafik
              // batang dan bisa disalahpahami sebagai catatan minum obat.
              if (statusLabel != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 6),

                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),

          const SizedBox(height: 36),

          // Tinggi 220 dipertahankan agar ukuran kartu tidak berubah.
          SizedBox(
            height: 220,
            child: item == null
                ? Center(
                    child: Text(
                      errorMessage ??
                          "Perjalanan pengobatan akan muncul setelah data pengobatan tersedia.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                : _journey(context, item),
          ),
        ],
      ),
    );
  }

  Widget _journey(BuildContext context, MyTreatment item) {
    final TreatmentProgress? progress = item.progress;

    final String elapsedValue;
    if (progress == null) {
      elapsedValue = "Belum tersedia";
    } else if (progress.elapsedDays == 0) {
      elapsedValue = "Belum dimulai";
    } else {
      elapsedValue =
          "${progress.elapsedDays} dari ${progress.totalDays} hari (${progress.percent}%)";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        _journeyRow(
          context,
          icon: Icons.play_circle_outline,
          label: "Mulai Terapi",
          value: item.startDateLabel ?? "Belum tersedia",
        ),

        _journeyRow(
          context,
          icon: Icons.timelapse,
          label: "Sudah Berjalan",
          value: elapsedValue,
        ),

        _journeyRow(
          context,
          icon: Icons.event_available_outlined,
          label: "Perkiraan Selesai",
          value: item.endDateLabel ?? "Belum tersedia",
        ),

        _journeyRow(
          context,
          icon: Icons.category_outlined,
          label: "Fase Terapi",
          value: item.phaseLabel ?? "Belum tersedia",
        ),
      ],
    );
  }

  Widget _journeyRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [

        Icon(
          icon,
          color: AppColors.primary,
          size: 26,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),

        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
