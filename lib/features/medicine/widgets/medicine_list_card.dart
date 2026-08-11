import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan nama obat contoh.
///
// TODO: Integrasikan daftar obat setelah backend menyediakan endpoint yang
// dapat diakses role patient. Nama dan kekuatan obat ada di MedicineResponse
// (name, strength, unit), sedangkan dosis pasien ada di
// MedicineScheduleResponse.dosage. Keduanya hanya terhubung ke pasien melalui
// treatment_id, dan GET /medicines sendiri adalah katalog seluruh obat
// sehingga tidak boleh ditampilkan sebagai obat milik pasien.
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

          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Data obat belum tersedia",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Informasi obat akan muncul setelah data pengobatan tersedia.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dipertahankan untuk dipakai kembali begitu daftar obat pasien dapat
  /// diambil dari backend, sehingga desain baris obat tidak perlu dibuat ulang.
  // ignore: unused_element
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