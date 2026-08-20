import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../ai_vot/pages/medicine_verification_page.dart';
import '../models/my_medicine_schedule.dart';

/// Daftar obat aktif milik pasien dari `GET /medicine-schedules/my`.
///
/// Nama berasal dari `medicine_name`, dosis dari `dosage`, jam minum dari
/// `drink_time`. Tidak ada mapping `medicine_id` ke nama di aplikasi.
class MedicineListCard extends StatelessWidget {
  const MedicineListCard({
    super.key,
    this.schedules = const <MyMedicineSchedule>[],
    this.errorMessage,
  });

  final List<MyMedicineSchedule> schedules;
  final String? errorMessage;

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

          if (schedules.isEmpty)
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
                    errorMessage ??
                        "Informasi obat akan muncul setelah data pengobatan tersedia.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            )
          else ...[
            for (int index = 0; index < schedules.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _medicineTile(context: context, schedule: schedules[index], 
                name: schedules[index].displayName,
                dosage: schedules[index].dosage.trim().isEmpty
                    ? "Dosis belum tersedia"
                    : schedules[index].dosage,
                badge: schedules[index].drinkTimeLabel ?? "Jam belum tersedia",
              ),
            ],
          ],
        ],
      ),
    ),
    );
  }

  Widget _medicineTile(context: context, schedule: schedules[index], {
    required String name,
    required String dosage,
    required String badge,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineVerificationPage(schedule: schedule),
          ),
        );
      },
      child: Padding(
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
            // Menampilkan jam minum dari drink_time, bukan label frekuensi:
            // backend tidak mengirim berapa kali obat diminum per hari.
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}