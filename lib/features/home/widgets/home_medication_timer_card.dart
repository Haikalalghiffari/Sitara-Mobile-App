import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

/// Kartu ini sengaja menampilkan empty state, bukan countdown contoh.
///
// TODO: Integrasikan MedicineSchedule API setelah backend menyediakan
// endpoint jadwal yang dapat diakses oleh role patient. Saat ini hanya ada
// GET /medicine-schedules ("Get All Schedules") yang mengembalikan jadwal
// seluruh pasien, dan responsnya tidak memuat patient_id sehingga jadwal
// milik pasien yang login tidak dapat dikenali tanpa menyaring data pasien
// lain. Setelah endpoint per pasien tersedia, countdown dan jam dihitung
// dari drink_time jadwal berikutnya.
class HomeMedicationTimerCard extends StatelessWidget {
  const HomeMedicationTimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: AppRadius.cardLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "JADWAL MINUM OBAT BERIKUTNYA",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              "-- : -- : --",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [

              Icon(
                Icons.schedule,
                color: Colors.white70,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                "Jadwal belum tersedia",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}