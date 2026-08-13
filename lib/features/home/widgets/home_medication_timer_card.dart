import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../medicine/models/my_medicine_schedule.dart';

/// Hitung mundur menuju jadwal minum obat berikutnya.
///
/// Sumber waktunya `drink_time` pada `MyMedicineScheduleResponse` dari
/// `GET /medicine-schedules/my`, dibandingkan dengan jam perangkat tanpa
/// konversi zona waktu. Bila jadwal tidak ada atau tidak terbaca, empty state
/// "-- : -- : --" dipertahankan.
class HomeMedicationTimerCard extends StatefulWidget {
  const HomeMedicationTimerCard({
    super.key,
    this.schedule,
    this.errorMessage,
  });

  /// Jadwal minum terdekat milik pasien yang sedang login.
  final MyMedicineSchedule? schedule;

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

  /// Ticker hanya dihidupkan saat ada jadwal yang jamnya terbaca, supaya
  /// kartu tidak melakukan rebuild tiap detik ketika menampilkan empty state.
  void _syncTicker() {
    final bool needsTicker = widget.schedule?.drinkMinutesOfDay != null;

    if (needsTicker) {
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
    final DateTime? nextDrink = widget.schedule?.nextOccurrence(now: now);

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
              _countdownLabel(nextDrink, now),
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
                  _scheduleLabel(nextDrink, now),
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

  String _countdownLabel(DateTime? nextDrink, DateTime now) {
    if (nextDrink == null) return "-- : -- : --";

    Duration remaining = nextDrink.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    final String hours =
        remaining.inHours.toString().padLeft(2, '0');
    final String minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$hours : $minutes : $seconds";
  }

  String _scheduleLabel(DateTime? nextDrink, DateTime now) {
    final String? time = widget.schedule?.drinkTimeLabel;

    if (nextDrink == null || time == null) {
      return widget.errorMessage ?? "Jadwal belum tersedia";
    }

    final bool isToday = nextDrink.year == now.year &&
        nextDrink.month == now.month &&
        nextDrink.day == now.day;

    return "${isToday ? 'Hari Ini' : 'Besok'} • $time";
  }
}
