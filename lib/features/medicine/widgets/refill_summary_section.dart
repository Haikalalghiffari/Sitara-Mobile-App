import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Ringkasan singkat sebelum `POST /refills`. Bukan langkah API terpisah.
class RefillSummarySection extends StatelessWidget {
  const RefillSummarySection({
    super.key,
    required this.medicineName,
    required this.quantity,
    this.reason,
  });

  final String? medicineName;
  final int quantity;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final String obat = medicineName?.trim().isNotEmpty == true
        ? medicineName!.trim()
        : "Belum tersedia";
    final String alasan = reason?.trim().isNotEmpty == true
        ? reason!.trim()
        : "Belum dipilih";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ringkasan",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(context, "Obat", obat),
              const SizedBox(height: 10),
              _row(context, "Jumlah", "$quantity"),
              const SizedBox(height: 10),
              _row(context, "Alasan", alasan),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            "$label:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
