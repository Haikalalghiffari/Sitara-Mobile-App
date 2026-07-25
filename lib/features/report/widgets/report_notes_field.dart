import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class ReportNotesField extends StatelessWidget {
  final TextEditingController? controller;

  const ReportNotesField({
    super.key,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "Catatan Tambahan (Opsional)",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                "Contoh: Saya merasa pusing setelah minum obat pagi ini...",
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),

            filled: true,
            fillColor: AppColors.surface,

            contentPadding: const EdgeInsets.all(
              AppSpacing.cardPaddingSmall,
            ),

            border: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.outlineVariant,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.outlineVariant,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}