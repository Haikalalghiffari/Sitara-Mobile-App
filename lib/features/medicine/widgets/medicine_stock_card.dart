import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan angka stok contoh.
///
// TODO: Integrasikan stok obat setelah backend menyediakan endpoint yang
// dapat diakses role patient. Stok sebenarnya ada di MedicineScheduleResponse
// (quantity_remaining / quantity_initial), tetapi GET /medicine-schedules
// mengembalikan jadwal seluruh pasien tanpa patient_id, dan satu-satunya
// penghubung ke pasien adalah treatment_id yang hanya bisa diperoleh lewat
// GET /treatments (require_nakes).
class MedicineStockCard extends StatelessWidget {
  const MedicineStockCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Stack(
        children: [

          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.medication,
              size: 120,
              color: AppColors.primary.withValues(alpha: .08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Stok Obat Saat Ini",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 14),

              Text(
                "Stok obat belum tersedia",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 12,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Data stok akan muncul setelah petugas kesehatan melengkapi data pengobatanmu.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}