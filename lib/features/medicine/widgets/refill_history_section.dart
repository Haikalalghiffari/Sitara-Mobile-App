import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

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
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<Refill> refills;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _notice(
        context,
        message: errorMessage!,
        showRetry: true,
      );
    }

    if (refills.isEmpty) {
      return _notice(
        context,
        message:
            "Belum ada permintaan pesan ulang. Permintaan yang Anda kirim akan muncul di sini.",
        showRetry: false,
      );
    }

    final List<Refill> sorted = Refill.sortedByNewest(refills);

    return Column(
      children: <Widget>[
        for (int index = 0; index < sorted.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _refillCard(context, sorted[index]),
        ],
      ],
    );
  }

  Widget _notice(
    BuildContext context, {
    required String message,
    required bool showRetry,
  }) {
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

          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          if (showRetry && onRetry != null) ...[
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
                child: Text(
                  "Obat #${refill.medicineId}",
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
