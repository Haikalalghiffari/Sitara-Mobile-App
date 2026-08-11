import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Grafik ini sengaja menampilkan empty state, bukan batang dengan nilai
/// contoh.
///
// TODO: Integrasikan riwayat mingguan setelah backend menyediakan endpoint
// verifikasi minum obat yang dapat diakses role patient. Riwayat harian
// berasal dari verification_date dan status pada VideoVerificationResponse,
// yang hanya terhubung ke pasien melalui medicine_schedule_id lalu
// treatment_id, sehingga belum dapat diambil oleh akun pasien.
class ProgressActivityChart extends StatelessWidget {
  const ProgressActivityChart({super.key});

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

          Row(
            children: [

              Expanded(
                child: Text(
                  "Aktivitas Mingguan",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

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
                "Tercatat",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Tinggi 220 dipertahankan agar ukuran kartu tidak berubah saat
          // grafik belum memiliki data.
          SizedBox(
            height: 220,
            child: Center(
              child: Text(
                "Riwayat progress belum tersedia",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}