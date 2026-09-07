import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';
import '../utils/refill_medicine_options.dart';

/// Pemilih obat untuk pesan ulang.
///
/// Satu obat: ditampilkan sebagai informasi, bukan dropdown.
/// Beberapa obat: dropdown. Bukan kartu detail yang bisa diklik.
class RefillMedicinePicker extends StatelessWidget {
  const RefillMedicinePicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.isLoading = false,
    this.errorMessage,
    this.enabled = true,
  });

  final List<MyMedicineSchedule> options;
  final MyMedicineSchedule? selected;
  final ValueChanged<MyMedicineSchedule?> onSelected;
  final bool isLoading;
  final String? errorMessage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pilih Obat",
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
          child: _body(context),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (options.isEmpty) {
      return Text(
        errorMessage ??
            "Data obat aktif belum tersedia. Hubungi petugas kesehatan.",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      );
    }

    if (options.length == 1) {
      return _medicineInfo(context, options.first);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey<int?>(selected?.medicineId),
          initialValue: selected?.medicineId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('Pilih obat yang akan dipesan ulang'),
          items: [
            for (final MyMedicineSchedule item in options)
              DropdownMenuItem<int>(
                value: item.medicineId,
                child: Text(item.displayName),
              ),
          ],
          onChanged: enabled
              ? (int? id) {
                  if (id == null) {
                    onSelected(null);
                    return;
                  }
                  for (final MyMedicineSchedule item in options) {
                    if (item.medicineId == id) {
                      onSelected(item);
                      return;
                    }
                  }
                }
              : null,
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          _medicineInfo(context, selected!),
        ],
      ],
    );
  }

  Widget _medicineInfo(BuildContext context, MyMedicineSchedule item) {
    final int stock = RefillMedicineOptions.stockQuantity(item);
    final String dosage = item.dosage.trim().isEmpty
        ? "Informasi dosis belum tersedia."
        : item.dosage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dosage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          stock > 0 ? "Stok: $stock" : "Stok tidak tersedia",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
