import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../models/refill.dart';

/// Riwayat pesan ulang obat dari `GET /refills/my`.
///
/// Menampilkan jumlah, alasan, keterangan, tanggal, status, dan catatan nakes
/// bila sudah ada. Tidak ada data contoh: daftar kosong tetap tampil sebagai
/// keterangan kosong.
class RefillHistorySection extends StatelessWidget {
  const RefillHistorySection({
    super.key,
    this.refills = const <Refill>[],
    this.schedules = const <MyMedicineSchedule>[],
    this.highlightedRefillId,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onStartRequest,
  });

  final List<Refill> refills;

  /// Jadwal dari `GET /medicine-schedules/my`, dipakai hanya untuk menampilkan
  /// `medicine_name`. Bukan katalog `/medicines`.
  final List<MyMedicineSchedule> schedules;
  final int? highlightedRefillId;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// CTA empty state. Tetap di halaman yang sama, menggulir ke formulir.
  final VoidCallback? onStartRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Riwayat Pesan Ulang",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: AppSpacing.md),

        _content(context),
      ],
    );
  }

  Widget _content(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Memuat riwayat...",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _errorState(context, errorMessage!);
    }

    if (refills.isEmpty) {
      return _emptyState(context);
    }

    final List<Refill> sorted = Refill.sortedByNewest(refills);
    final Refill? highlighted = Refill.findById(sorted, highlightedRefillId);
    final List<Refill> visible = highlighted == null
        ? sorted
        : <Refill>[
            highlighted,
            ...sorted.where((Refill item) => item.id != highlighted.id),
          ];

    return Column(
      children: <Widget>[
        for (int index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _refillCard(context, visible[index]),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
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
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 36,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Belum ada riwayat permintaan obat.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Isi formulir di atas, lalu tekan Kirim Permintaan.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          if (onStartRequest != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onStartRequest,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Pesan Ulang Obat"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gagal memuat riwayat.",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: const Text("Coba Lagi"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _refillCard(BuildContext context, Refill refill) {
    final String? statusLabel = refill.statusLabel;
    final String? dateLabel = refill.createdAtLabel;
    final String? detail = refill.descriptionText;
    final String? nurseNote = refill.nurseNoteText;
    final bool highlighted = refill.id == highlightedRefillId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: Text(
                  MyMedicineSchedule.nameForId(schedules, refill.medicineId),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              if (statusLabel != null) ...[
                const SizedBox(width: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),

          if (dateLabel != null) ...[
            const SizedBox(height: 4),

            Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],

          const SizedBox(height: 10),

          Text(
            "Jumlah diminta: ${refill.quantity}",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),

          if (refill.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              "Alasan: ${refill.reason}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ],

          if (detail != null) ...[
            const SizedBox(height: 10),

            Text(
              detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],

          if (nurseNote != null) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPaddingSmall),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Catatan Petugas",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    nurseNote,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
