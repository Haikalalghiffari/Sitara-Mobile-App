import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Pilihan alasan pesan ulang obat.
///
/// Alasan yang dipilih dipegang oleh halaman, bukan oleh widget ini, supaya
/// nilainya dapat dikirim sebagai `reason` pada `POST /refills`. Backend
/// menyimpan `reason` sebagai teks bebas, jadi label di bawah dikirim apa
/// adanya.
///
/// Tidak ada pilihan yang aktif di awal: mengirim alasan yang tidak pernah
/// dipilih pasien sama dengan mengarang isi permintaan.
class RefillReasonSection extends StatelessWidget {
  const RefillReasonSection({
    super.key,
    this.selectedReason,
    required this.onChanged,
  });

  final String? selectedReason;
  final ValueChanged<String> onChanged;

  static const List<String> reasons = <String>[
    "Obat Hilang",
    "Obat Rusak / Basah",
    "Lupa Membawa Saat Bepergian",
    "Lainnya",
  ];

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

        for (int index = 0; index < reasons.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _ReasonTile(
            title: reasons[index],
            selected: selectedReason == reasons[index],
            onTap: () {
              onChanged(reasons[index]);
            },
          ),
        ],
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
