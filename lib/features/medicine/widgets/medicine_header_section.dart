import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class MedicineHeaderSection extends StatelessWidget {
  const MedicineHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Logistik Obat",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          "Kelola stok dan jadwal pengambilan obat Anda.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}