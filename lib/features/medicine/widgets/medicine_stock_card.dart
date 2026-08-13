import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';

/// Kartu stok obat.
///
/// Angka diambil dari `quantity_remaining` dan `quantity_initial` pada
/// `MyMedicineScheduleResponse` (`GET /medicine-schedules/my`). Satuan obat
/// tidak ditulis karena backend tidak mengirimnya, dan sisa hari tidak
/// dihitung karena jumlah dosis per hari juga tidak tersedia.
class MedicineStockCard extends StatelessWidget {
  const MedicineStockCard({
    super.key,
    this.schedule,
    this.totalCount = 0,
    this.errorMessage,
  });

  /// Obat dengan sisa stok proporsional paling sedikit.
  final MyMedicineSchedule? schedule;

  /// Banyaknya jadwal obat milik pasien, untuk menjelaskan bahwa angka di
  /// kartu ini mewakili satu obat saja.
  final int totalCount;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final MyMedicineSchedule? item = schedule;

    return _buildCard(context, item);
  }

  Widget _buildCard(BuildContext context, MyMedicineSchedule? item) {
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

              if (item == null)
                Text(
                  "Stok obat belum tersedia",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                )
              else
                RichText(
                  text: TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    children: [
                      TextSpan(
                        text: "${item.quantityRemaining}",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " / ${item.quantityInitial}",
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: item?.remainingFraction ?? 0,
                  minHeight: 12,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _caption(item),
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

  String _caption(MyMedicineSchedule? item) {
    if (item == null) {
      return errorMessage ??
          "Data stok akan muncul setelah petugas kesehatan melengkapi data pengobatanmu.";
    }

    final String base =
        "Perkiraan sisa hari belum dapat ditampilkan. Tanyakan kepada petugas kesehatan bila stok menipis.";

    if (totalCount > 1) {
      return "$base Angka di atas adalah obat dengan sisa paling sedikit dari $totalCount obat Anda.";
    }

    return base;
  }
}