import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class RefillDetailField extends StatelessWidget {
  const RefillDetailField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Keterangan Detail",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: AppColors.outlineVariant,
            ),
          ),
          child: TextField(
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  "Jelaskan secara singkat penyebab Anda memerlukan pesan ulang obat...",
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(.8),
              ),
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "Minimal 20 karakter",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}