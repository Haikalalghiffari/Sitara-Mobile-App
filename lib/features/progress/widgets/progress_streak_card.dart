import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan jumlah hari contoh.
///
// TODO: Integrasikan runtutan harian setelah backend menyediakan endpoint
// verifikasi minum obat yang dapat diakses role patient. Backend tidak
// menyimpan nilai runtutan secara langsung; nilai ini perlu dihitung dari
// verification_date pada VideoVerificationResponse yang berstatus verified,
// dan data tersebut belum dapat diakses pasien.
class ProgressStreakCard extends StatelessWidget {
  const ProgressStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.card,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.health_and_safety,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 22,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    "RUNTUTAN HARIAN",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                "Belum tersedia",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 22),

              Text(
                "Runtutan harian akan muncul setelah data verifikasi minum obat tersedia.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.7,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}