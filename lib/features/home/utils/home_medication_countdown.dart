import 'package:flutter/foundation.dart';

import '../../ai_vot/models/daily_medication.dart';
import '../../medicine/models/my_medicine_schedule.dart';

/// Jam dinding 00–23 dari string API, tanpa `DateTime.parse` / konversi zona.
class HomeClockTime {
  const HomeClockTime({
    required this.hour,
    required this.minute,
  });

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// Parse `drink_time` / `scheduled_time` sebagai jam kalender.
  ///
  /// `"12:35:00"` → hour 12, minute 35. Bukan 00:35.
  /// Offset `+07:00` / `Z` dibuang dari string, tidak di-apply ke jam.
  static HomeClockTime? parse(String raw) {
    String value = raw.trim();
    if (value.isEmpty) return null;

    value = value.replaceFirst(RegExp(r'Z$', caseSensitive: false), '');
    value = value.replaceFirst(RegExp(r'[+-]\d{2}:\d{2}$'), '');
    value = value.replaceFirst(RegExp(r'\.\d+$'), '');

    final int tIndex = value.indexOf('T');
    if (tIndex >= 0 && tIndex < value.length - 1) {
      value = value.substring(tIndex + 1);
    } else {
      final int space = value.indexOf(' ');
      if (space >= 0 && space < value.length - 1) {
        final String after = value.substring(space + 1);
        if (RegExp(r'^\d{1,2}:').hasMatch(after)) {
          value = after;
        }
      }
    }

    final List<String> parts = value.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0].trim());
    final int? minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return HomeClockTime(hour: hour, minute: minute);
  }
}

/// Target countdown kartu Home: occurrence resmi berikutnya.
class HomeDrinkTarget {
  const HomeDrinkTarget({
    required this.at,
    required this.timeLabel,
  });

  final DateTime at;
  final String timeLabel;

  bool isToday(DateTime now) {
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  String scheduleLabelAt(DateTime now) {
    final String day = isToday(now) ? 'Hari Ini' : 'Besok';
    return '$day • $timeLabel';
  }

  String countdownLabel(DateTime now) {
    Duration remaining = at.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;
    final String hours = remaining.inHours.toString().padLeft(2, '0');
    final String minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }
}

/// Next occurrence dari `MedicineSchedule.drink_time` + tanggal kalender lokal.
class HomeMedicationCountdown {
  const HomeMedicationCountdown._();

  static String? _lastDebugKey;

  static String hhmm(int minutes) {
    final String hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final String minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static HomeDrinkTarget? resolve({
    required List<DailyMedication> today,
    required List<MyMedicineSchedule> schedules,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();
    final List<HomeClockTime> official = _officialClocks(schedules);
    final HomeDrinkTarget? target = official.isEmpty
        ? _withoutOfficialSchedules(today, clock)
        : _fromOfficialSlots(
            official: official,
            today: today,
            now: clock,
          );
    _debugResolve(
      schedules: schedules,
      official: official,
      now: clock,
      target: target,
    );
    return target;
  }

  static HomeDrinkTarget _fromOfficialSlots({
    required List<HomeClockTime> official,
    required List<DailyMedication> today,
    required DateTime now,
  }) {
    final Set<int> completed = _completedOfficialMinutes(
      official: official,
      today: today,
    );

    for (final HomeClockTime slot in _todayOccurrenceClocks(
      official: official,
      today: today,
    )) {
      if (completed.contains(slot.minutesOfDay)) continue;
      return _onDate(now, slot);
    }

    return _onDate(_nextCalendarDay(now), official.first);
  }

  static List<HomeClockTime> _todayOccurrenceClocks({
    required List<HomeClockTime> official,
    required List<DailyMedication> today,
  }) {
    if (today.isEmpty) return official;

    final Set<int> todayMinutes = today
        .map(
          (DailyMedication item) => HomeClockTime.parse(item.scheduledTime),
        )
        .whereType<HomeClockTime>()
        .map((HomeClockTime item) => item.minutesOfDay)
        .toSet();

    final List<HomeClockTime> matched = official
        .where((HomeClockTime item) => todayMinutes.contains(item.minutesOfDay))
        .toList();
    if (matched.isNotEmpty) return matched;
    return official.take(today.length).toList();
  }

  static Set<int> _completedOfficialMinutes({
    required List<HomeClockTime> official,
    required List<DailyMedication> today,
  }) {
    final List<int> verifiedMinutes = today
        .where((DailyMedication item) => item.isServerVerified)
        .map(
          (DailyMedication item) => HomeClockTime.parse(item.scheduledTime),
        )
        .whereType<HomeClockTime>()
        .map((HomeClockTime item) => item.minutesOfDay)
        .toList();

    final Set<int> completed = <int>{};
    final Set<int> used = <int>{};

    for (final HomeClockTime slot in official) {
      for (int i = 0; i < verifiedMinutes.length; i++) {
        if (used.contains(i)) continue;
        if (verifiedMinutes[i] == slot.minutesOfDay) {
          completed.add(slot.minutesOfDay);
          used.add(i);
          break;
        }
      }
    }

    for (final HomeClockTime slot in official) {
      if (completed.contains(slot.minutesOfDay)) continue;
      for (int i = 0; i < verifiedMinutes.length; i++) {
        if (used.contains(i)) continue;
        completed.add(slot.minutesOfDay);
        used.add(i);
        break;
      }
    }

    return completed;
  }

  static HomeDrinkTarget? _withoutOfficialSchedules(
    List<DailyMedication> today,
    DateTime now,
  ) {
    final List<HomeClockTime> remaining = today
        .where((DailyMedication item) => !item.isServerVerified)
        .map(
          (DailyMedication item) => HomeClockTime.parse(item.scheduledTime),
        )
        .whereType<HomeClockTime>()
        .toList()
      ..sort(
        (HomeClockTime a, HomeClockTime b) =>
            a.minutesOfDay.compareTo(b.minutesOfDay),
      );

    if (remaining.isNotEmpty) return _onDate(now, remaining.first);

    final List<HomeClockTime> timed = today
        .map(
          (DailyMedication item) => HomeClockTime.parse(item.scheduledTime),
        )
        .whereType<HomeClockTime>()
        .toList()
      ..sort(
        (HomeClockTime a, HomeClockTime b) =>
            a.minutesOfDay.compareTo(b.minutesOfDay),
      );
    if (timed.isEmpty) return null;
    return _onDate(_nextCalendarDay(now), timed.first);
  }

  static DateTime _nextCalendarDay(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }

  static HomeDrinkTarget _onDate(DateTime day, HomeClockTime clock) {
    return HomeDrinkTarget(
      at: DateTime(
        day.year,
        day.month,
        day.day,
        clock.hour,
        clock.minute,
      ),
      timeLabel: hhmm(clock.minutesOfDay),
    );
  }

  static List<HomeClockTime> _officialClocks(
    List<MyMedicineSchedule> schedules,
  ) {
    final Map<int, HomeClockTime> unique = <int, HomeClockTime>{};
    for (final MyMedicineSchedule item in schedules) {
      final HomeClockTime? clock = HomeClockTime.parse(item.drinkTime);
      if (clock == null) continue;
      unique[clock.minutesOfDay] = clock;
    }
    final List<HomeClockTime> sorted = unique.values.toList()
      ..sort(
        (HomeClockTime a, HomeClockTime b) =>
            a.minutesOfDay.compareTo(b.minutesOfDay),
      );
    return sorted;
  }

  static void _debugResolve({
    required List<MyMedicineSchedule> schedules,
    required List<HomeClockTime> official,
    required DateTime now,
    required HomeDrinkTarget? target,
  }) {
    if (!kDebugMode) return;
    final String raw =
        schedules.map((MyMedicineSchedule item) => item.drinkTime).join(' | ');
    final String parsed = official
        .map(
          (HomeClockTime item) =>
              'hour=${item.hour} minute=${item.minute}',
        )
        .join(' | ');
    final String key = '$raw|$parsed|${target?.at}';
    if (key == _lastDebugKey) return;
    _lastDebugKey = key;
    debugPrint('[HomeCountdown] drink_time raw = $raw');
    debugPrint('[HomeCountdown] parsed hour/minute = $parsed');
    debugPrint('[HomeCountdown] timezone = local DateTime (device)');
    debugPrint('[HomeCountdown] now = $now');
    debugPrint('[HomeCountdown] target = ${target?.at}');
    debugPrint(
      '[HomeCountdown] difference = ${target?.at.difference(now)}',
    );
  }
}
