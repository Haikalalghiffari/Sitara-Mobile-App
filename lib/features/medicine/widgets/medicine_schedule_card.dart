import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

class MedicineScheduleCard extends StatelessWidget {
  const MedicineScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
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
        "Jadwal Pengambilan Berikutnya",
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
            children: const [

              Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 30,
              ),

              SizedBox(width: 16),

              Text(
                "15 Juni 2024",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 34,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [

              Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 30,
              ),

              SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Puskesmas Melati",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Jl. Mawar No.12, Jakarta Timur",
                      style: TextStyle(
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
              onPressed: () {},
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