import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/my_medicine_schedule.dart';

/// Kartu jadwal minum obat berikutnya.
///
/// Jam diambil dari `drink_time` pada `MyMedicineScheduleResponse`. Judul
/// kartu memakai kata "minum" karena `drink_time` adalah waktu minum harian,
/// bukan tanggal pengambilan obat.
///
// Tanggal dan lokasi pengambilan obat tetap empty state: tidak ada field nama
// fasilitas, alamat, latitude, maupun longitude di endpoint mana pun yang
// dapat diakses role patient, sehingga tombol "Lihat Peta" dibiarkan nonaktif.
// control_date pada ControlScheduleResponse sengaja tidak dipakai di sini
// karena itu jadwal kontrol, bukan jadwal minum obat.
class MedicineScheduleCard extends StatelessWidget {
  const MedicineScheduleCard({
    super.key,
    this.schedule,
    this.errorMessage,
  });

  final MyMedicineSchedule? schedule;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final String? timeLabel = schedule?.drinkTimeLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.cardLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
  children: [
    const Icon(
      Icons.event_repeat,
      color: Colors.white,
    ),

    const SizedBox(width: 10),

    Expanded(
      child: Text(
        "Jadwal Minum Obat Berikutnya",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    ),
  ],
),

          const SizedBox(height: 28),

          Row(
            children: [

              const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 30,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  timeLabel ?? "Belum tersedia",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 30,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Lokasi belum tersedia",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      errorMessage ??
                          "Tanggal dan lokasi pengambilan obat belum tersedia di aplikasi. Tanyakan kepada petugas kesehatan.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              onPressed: null,
              icon: const Icon(Icons.map_outlined),
              label: const Text(
                "Lihat Peta",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}