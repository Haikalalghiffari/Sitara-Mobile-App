import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/complaint.dart';

/// Riwayat keluhan pasien dari `GET /complaints/my`.
///
/// Menampilkan kategori, catatan, tanggal, status, dan balasan nakes bila
/// sudah ada. Tidak ada data contoh: daftar kosong tetap tampil sebagai
/// keterangan kosong.
class ReportHistorySection extends StatelessWidget {
  const ReportHistorySection({
    super.key,
    this.complaints = const <Complaint>[],
    this.highlightedComplaintId,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<Complaint> complaints;
  final int? highlightedComplaintId;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Riwayat Keluhan",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

    if (complaints.isEmpty) {
      return _notice(
        context,
        message:
            "Belum ada keluhan yang dikirim. Keluhan yang Anda kirim akan muncul di sini.",
        showRetry: false,
      );
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < complaints.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _complaintCard(context, complaints[index]),
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

  Widget _complaintCard(BuildContext context, Complaint complaint) {
    final String? statusLabel = complaint.statusLabel;
    final String? dateLabel = complaint.createdAtLabel;
    final String? reply = complaint.responseText;
    final bool highlighted = complaint.id == highlightedComplaintId;

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
                  complaint.category.trim().isEmpty
                      ? "Keluhan"
                      : complaint.category,
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
            complaint.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),

          if (reply != null) ...[
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
                    "Balasan Petugas",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    reply,
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
