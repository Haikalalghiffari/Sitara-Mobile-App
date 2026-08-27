import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../ai_vot/models/daily_medication.dart';
import '../../medicine/models/my_medicine_schedule.dart';
import '../utils/home_medication_countdown.dart';

/// Hitung mundur menuju occurrence resmi berikutnya.
///
/// Target dihitung ulang tiap detik dari `drink_time` + status today, tanpa
/// restart halaman.
class HomeMedicationTimerCard extends StatefulWidget {
  const HomeMedicationTimerCard({
    super.key,
    this.today = const <DailyMedication>[],
    this.schedules = const <MyMedicineSchedule>[],
    this.errorMessage,
  });

  final List<DailyMedication> today;
  final List<MyMedicineSchedule> schedules;
  final String? errorMessage;

  @override
  State<HomeMedicationTimerCard> createState() =>
      _HomeMedicationTimerCardState();
}

class _HomeMedicationTimerCardState extends State<HomeMedicationTimerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant HomeMedicationTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _hasSource {
    return widget.today.isNotEmpty || widget.schedules.isNotEmpty;
  }

  void _syncTicker() {
    if (_hasSource) {
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) setState(() {});
        },
      );
      return;
    }

    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: widget.today,
      schedules: widget.schedules,
      now: now,
    );

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
              target?.countdownLabel(now) ?? "-- : -- : --",
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
            children: [

              const Icon(
                Icons.schedule,
                color: Colors.white70,
                size: 18,
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  target?.scheduleLabelAt(now) ??
                      widget.errorMessage ??
                      "Jadwal belum tersedia",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
