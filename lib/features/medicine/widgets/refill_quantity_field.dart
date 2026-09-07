import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Jumlah refill yang dikunci ke stok obat yang dipilih.
class RefillQuantityField extends StatelessWidget {
  const RefillQuantityField({
    super.key,
    required this.quantity,
    required this.stock,
    this.hasMedicine = true,
  });

  final int quantity;
  final int stock;
  final bool hasMedicine;

  static const int minQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final bool stockMissing = !hasMedicine || stock < minQuantity;
    final String helper = stockMissing
        ? (hasMedicine
            ? "Stok obat tidak tersedia."
            : "Pilih obat terlebih dahulu.")
        : "Jumlah dikunci sesuai stok obat yang dipilih.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Jumlah yang Diminta",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            stockMissing ? "—" : "$quantity",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
