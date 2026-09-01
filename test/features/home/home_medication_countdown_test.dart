import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/home/utils/home_medication_countdown.dart';
import 'package:sitara/features/home/widgets/home_medication_timer_card.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';

DailyMedication _dose({
  required int id,
  required String time,
  required String status,
  bool? eligible,
}) {
  return DailyMedication(
    dailyMedicationId: id,
    medicineScheduleId: id + 10,
    medicineId: 2,
    medicineName: 'Rifampicin',
    dosage: '1 tablet',
    scheduledDate: '2026-08-27',
    scheduledTime: time,
    quantityRemaining: 30,
    status: status,
    votStep: status == 'verified' ? 'verified' : 'waiting',
    eligible: eligible,
  );
}

MyMedicineSchedule _schedule(String drinkTime) {
  return MyMedicineSchedule(
    treatmentId: 1,
    medicineId: 2,
    medicineName: 'Rifampicin',
    dosage: '1 tablet',
    quantityInitial: 30,
    quantityRemaining: 20,
    drinkTime: drinkTime,
  );
}

void main() {
  test('12:35 wall clock does not become 00:35', () {
    final HomeClockTime? clock = HomeClockTime.parse('12:35:00');
    expect(clock, isNotNull);
    expect(clock!.hour, 12);
    expect(clock.minute, 35);
    expect(clock.hour, isNot(0));
  });

  test('ISO drink_time with Jakarta offset keeps hour 12', () {
    final HomeClockTime? clock =
        HomeClockTime.parse('2026-08-27T12:35:00+07:00');
    expect(clock!.hour, 12);
    expect(clock.minute, 35);
    expect(clock.hour, isNot(5));
    expect(clock.hour, isNot(0));
  });

  test('CASE: VOT at 12:35:00 targets tomorrow 12:35 for 24 hours', () {
    final DateTime now = DateTime(2026, 8, 27, 12, 35);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '12:35:00', status: 'verified', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[_schedule('12:35:00')],
      now: now,
    );

    expect(target!.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.at.hour, 12);
    expect(target.scheduleLabelAt(now), 'Besok • 12:35');
    expect(target.countdownLabel(now), '24 : 00 : 00');
    expect(target.countdownLabel(now), isNot('12 : 00 : 00'));
    expect(target.countdownLabel(now), isNot('11 : 59 : 56'));
    expect(target.timeLabel, isNot('00:35'));
  });

  test('CASE: VOT at 12:35:04 counts 23:59:56 to tomorrow 12:35', () {
    final DateTime now = DateTime(2026, 8, 27, 12, 35, 4);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '12:35:00', status: 'verified', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[_schedule('12:35:00')],
      now: now,
    );

    expect(target!.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.at.hour, 12);
    expect(target.scheduleLabelAt(now), 'Besok • 12:35');
    expect(target.countdownLabel(now), '23 : 59 : 56');
    expect(target.countdownLabel(now), isNot('11 : 59 : 56'));
  });

  test('CASE: VOT at 13:35 still targets tomorrow 12:35', () {
    final DateTime now = DateTime(2026, 8, 27, 13, 35);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '12:35:00', status: 'verified', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[_schedule('12:35:00')],
      now: now,
    );

    expect(target!.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.timeLabel, isNot('13:35'));
    expect(target.scheduleLabelAt(now), 'Besok • 12:35');
    expect(target.countdownLabel(now), '23 : 00 : 00');
  });

  test('ISO +07:00 drink_time after VOT still targets tomorrow 12:35', () {
    final DateTime now = DateTime(2026, 8, 27, 12, 35, 4);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(
          id: 1,
          time: '2026-08-27T12:35:00+07:00',
          status: 'verified',
          eligible: false,
        ),
      ],
      schedules: <MyMedicineSchedule>[
        _schedule('2026-08-27T12:35:00+07:00'),
      ],
      now: now,
    );

    expect(target!.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.at.hour, 12);
    expect(target.countdownLabel(now), '23 : 59 : 56');
  });

  test('completed_at-like 13:35 scheduled_time is not the next drink_time', () {
    final DateTime now = DateTime(2026, 8, 27, 13, 35);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '13:35:00', status: 'verified', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[_schedule('12:35:00')],
      now: now,
    );

    expect(target!.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.scheduleLabelAt(now), 'Besok • 12:35');
  });

  test('12:35 and 18:00: after 12:35 verified, next is today 18:00', () {
    final DateTime now = DateTime(2026, 8, 27, 12, 35);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '12:35:00', status: 'verified', eligible: false),
        _dose(id: 2, time: '18:00:00', status: 'pending', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[
        _schedule('12:35:00'),
        _schedule('18:00:00'),
      ],
      now: now,
    );

    expect(target!.isToday(now), isTrue);
    expect(target.scheduleLabelAt(now), 'Hari Ini • 18:00');
    expect(target.at, DateTime(2026, 8, 27, 18, 0));
  });

  test('12:35 and 18:00 both verified uses tomorrow 12:35, not 18:00', () {
    final DateTime now = DateTime(2026, 8, 27, 18, 0);
    final HomeDrinkTarget? target = HomeMedicationCountdown.resolve(
      today: <DailyMedication>[
        _dose(id: 1, time: '12:35:00', status: 'verified', eligible: false),
        _dose(id: 2, time: '18:00:00', status: 'verified', eligible: false),
      ],
      schedules: <MyMedicineSchedule>[
        _schedule('12:35:00'),
        _schedule('18:00:00'),
      ],
      now: now,
    );

    expect(target!.scheduleLabelAt(now), 'Besok • 12:35');
    expect(target.at, DateTime(2026, 8, 28, 12, 35));
    expect(target.timeLabel, isNot('18:00'));
  });

  testWidgets('home card shows Besok 12:35 after that slot is verified',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeMedicationTimerCard(
            today: <DailyMedication>[
              _dose(id: 1, time: '12:35:00', status: 'verified'),
            ],
            schedules: <MyMedicineSchedule>[_schedule('12:35:00')],
          ),
        ),
      ),
    );

    expect(find.text('JADWAL MINUM OBAT BERIKUTNYA'), findsOneWidget);
    expect(find.text('Besok • 12:35'), findsOneWidget);
    expect(find.text('Besok • 00:35'), findsNothing);
    expect(find.text('-- : -- : --'), findsNothing);
  });
}
