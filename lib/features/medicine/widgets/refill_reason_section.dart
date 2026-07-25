import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class RefillReasonSection extends StatefulWidget {
  const RefillReasonSection({super.key});

  @override
  State<RefillReasonSection> createState() =>
      _RefillReasonSectionState();
}

class _RefillReasonSectionState
    extends State<RefillReasonSection> {
  String selectedReason = "Obat Hilang";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mengapa Anda memerlukan\npesan ulang?",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 20),

        _ReasonTile(
          title: "Obat Hilang",
          selected: selectedReason == "Obat Hilang",
          onTap: () {
            setState(() {
              selectedReason = "Obat Hilang";
            });
          },
        ),

        const SizedBox(height: 12),

        _ReasonTile(
          title: "Obat Rusak / Basah",
          selected: selectedReason == "Obat Rusak / Basah",
          onTap: () {
            setState(() {
              selectedReason = "Obat Rusak / Basah";
            });
          },
        ),

        const SizedBox(height: 12),

        _ReasonTile(
          title: "Lupa Membawa Saat Bepergian",
          selected:
              selectedReason == "Lupa Membawa Saat Bepergian",
          onTap: () {
            setState(() {
              selectedReason =
                  "Lupa Membawa Saat Bepergian";
            });
          },
        ),

        const SizedBox(height: 12),

        _ReasonTile(
          title: "Lainnya",
          selected: selectedReason == "Lainnya",
          onTap: () {
            setState(() {
              selectedReason = "Lainnya";
            });
          },
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}