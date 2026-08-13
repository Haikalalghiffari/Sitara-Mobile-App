import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/control_schedule.dart';

/// Kartu jadwal kontrol berikutnya di MedicinePage.
///
/// Seluruh isinya berasal dari `ControlScheduleResponse` (`GET
/// /control-schedules/my`): `control_date`, `control_time`, `status`, dan
/// `doctor_note`. `control_time` ditampilkan apa adanya tanpa konversi UTC.
///
/// Jadwal minum obat tidak ditampilkan di sini karena sudah ada di HomePage.
class ControlScheduleCard extends StatelessWidget {
  const ControlScheduleCard({
    super.key,
    this.schedule,
    this.errorMessage,
  });

  final ControlSchedule? schedule;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final ControlSchedule? item = schedule;

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
            children: const [

              Icon(
                Icons.event_available,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  "Jadwal Kontrol Berikutnya",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          if (item == null)
            ..._emptyState()
          else
            ..._scheduleDetail(item),
        ],
      ),
    );
  }

  List<Widget> _emptyState() {
    return <Widget>[

      const Text(
        "Belum ada jadwal kontrol",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        errorMessage ??
            "Jadwal kontrol akan muncul setelah petugas kesehatan menetapkannya.",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 17,
        ),
      ),
    ];
  }

  List<Widget> _scheduleDetail(ControlSchedule item) {
    final String? statusLabel = item.statusLabel;
    final String? note = item.doctorNoteText;

    return <Widget>[

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
              item.dateLabel ?? "Tanggal belum tersedia",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      Row(
        children: [

          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 30,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              item.timeLabel ?? "Jam belum tersedia",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),

          if (statusLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),

      if (note != null) ...[

        const SizedBox(height: 22),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Icon(
              Icons.sticky_note_2_outlined,
              color: Colors.white,
              size: 30,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Catatan Dokter",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    note,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ];
  }
}
