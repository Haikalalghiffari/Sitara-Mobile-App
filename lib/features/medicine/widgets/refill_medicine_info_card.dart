import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../models/refill.dart';

/// Obat yang akan dipesan ulang, beserta status permintaan terakhir.
///
/// Data obat berasal dari `GET /medicine-schedules/my` (`medicine_name`,
/// `dosage`, `quantity_initial`, `quantity_remaining`). Nama ditampilkan
/// apa adanya dari `medicine_name`, bukan dari mapping `medicine_id`.
///
/// Status berasal dari `RefillResponse.status` (`GET /refills/my`), bukan dari
/// status buatan aplikasi.
class RefillMedicineInfoCard extends StatelessWidget {
  const RefillMedicineInfoCard({
    super.key,
    this.schedule,
    this.latestRefill,
    this.errorMessage,
  });

  final MyMedicineSchedule? schedule;

  /// Permintaan pesan ulang terbaru milik pasien, null bila belum ada.
  final Refill? latestRefill;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final MyMedicineSchedule? item = schedule;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      item == null
                          ? "Data obat belum tersedia"
                          : item.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _dosageText(item),
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

              _statusChip(context),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 18),

          Row(
            children: [

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Sisa Obat Saat Ini",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item == null
                          ? "Belum tersedia"
                          : "${item.quantityRemaining} dari ${item.quantityInitial}",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: item == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (item == null) ...[
            const SizedBox(height: 16),

            Text(
              errorMessage ??
                  "Informasi obat akan muncul setelah petugas kesehatan melengkapi jadwal obat Anda.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _dosageText(MyMedicineSchedule? item) {
    if (item == null) return "Informasi dosis belum tersedia.";

    final String dosage = item.dosage.trim();
    if (dosage.isEmpty) return "Informasi dosis belum tersedia.";
    return dosage;
  }

  /// Chip status memakai label dari backend. Bila pasien belum pernah mengirim
  /// permintaan, atau nilai `status` di luar `RefillRequestStatus`, warna netral
  /// dipakai agar tidak terbaca sebagai status yang datang dari server.
  Widget _statusChip(BuildContext context) {
    final Refill? refill = latestRefill;
    final String? label = refill?.statusLabel;

    final Color background;
    final Color foreground;

    switch (refill?.status.toLowerCase()) {
      case 'pending':
        background = AppColors.warningContainer;
        foreground = AppColors.onWarningContainer;
        break;
      case 'approved':
        background = AppColors.successContainer;
        foreground = AppColors.onSuccessContainer;
        break;
      case 'rejected':
        background = AppColors.errorContainer;
        foreground = AppColors.onErrorContainer;
        break;
      default:
        background = AppColors.surfaceContainerHigh;
        foreground = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "Status:\n${label ?? "Belum ada permintaan"}",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
