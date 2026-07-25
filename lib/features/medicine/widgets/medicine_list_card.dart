import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class MedicineListCard extends StatelessWidget {
  const MedicineListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "DAFTAR OBAT AKTIF",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
              ),
            ),
          ),

          const Divider(height: 1),

          _medicineTile(
            name: "Rifampisin",
            dosage: "450mg • 1x Sehari",
          ),

          const Divider(height: 1),

          _medicineTile(
            name: "Isoniazid",
            dosage: "300mg • 1x Sehari",
          ),
        ],
      ),
    );
  }

  Widget _medicineTile({
    required String name,
    required String dosage,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  dosage,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "HARIAN",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}