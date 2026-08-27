import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/ai_vot/utils/today_medication_picker.dart';
import 'package:sitara/features/ai_vot/utils/vot_flow.dart';
import 'package:sitara/features/ai_vot/widgets/vot_schedule_info.dart';

DailyMedication _item({
  required int id,
  required String time,
  required String status,
  String votStep = 'waiting',
  bool? eligible,
}) {
  return DailyMedication(
    dailyMedicationId: id,
    medicineScheduleId: id + 10,
    medicineId: 2,
    medicineName: 'Promag',
    dosage: '1 tablet',
    scheduledDate: '2026-08-27',
    scheduledTime: time,
    quantityRemaining: 30,
    status: status,
    votStep: votStep,
    eligible: eligible,
  );
}

void main() {
  test('parses GET /medications/today eligible true', () {
    final DailyMedication item = DailyMedication.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 4,
      'medicine_id': 2,
      'medicine_name': 'Promag',
      'dosage': '1 tablet',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '09:48:00',
      'quantity_remaining': 30,
      'status': 'pending',
      'vot_step': 'waiting',
      'eligible': true,
    });

    expect(item.eligible, isTrue);
    expect(item.canStartOrResume, isTrue);
    expect(item.scheduledTimeLabel, '09:48');
  });

  test('parses GET /medications/today eligible false', () {
    final DailyMedication item = DailyMedication.fromJson(<String, dynamic>{
      'daily_medication_id': 2,
      'medicine_schedule_id': 5,
      'medicine_id': 2,
      'medicine_name': 'Promag',
      'dosage': '1 tablet',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '18:00:00',
      'quantity_remaining': 30,
      'status': 'pending',
      'vot_step': 'waiting',
      'eligible': false,
    });

    expect(item.eligible, isFalse);
    expect(item.canStartOrResume, isFalse);
  });

  test('missing eligible is null, not default true', () {
    final DailyMedication item = DailyMedication.fromJson(<String, dynamic>{
      'daily_medication_id': 3,
      'medicine_schedule_id': 6,
      'medicine_id': 2,
      'medicine_name': 'Promag',
      'dosage': '1 tablet',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '20:00:00',
      'quantity_remaining': 30,
      'status': 'in_progress',
      'vot_step': 'face_verified',
    });

    expect(item.eligible, isNull);
    expect(item.isInProgress, isTrue);
    expect(item.canStartOrResume, isTrue);
  });

  test('list considers every medication, not only first', () {
    final List<DailyMedication> today = <DailyMedication>[
      _item(id: 1, time: '09:48:00', status: 'pending', eligible: false),
      _item(id: 2, time: '13:00:00', status: 'pending', eligible: true),
      _item(id: 3, time: '18:00:00', status: 'pending', eligible: false),
    ];
    expect(today, hasLength(3));
    expect(TodayMedicationPicker.pick(today)?.dailyMedicationId, 2);
  });

  test('selects in_progress over other eligible items', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(id: 1, time: '08:00:00', status: 'pending', eligible: true),
        _item(
          id: 2,
          time: '20:00:00',
          status: 'in_progress',
          votStep: 'face_verified',
          eligible: true,
        ),
      ],
    );
    expect(picked?.dailyMedicationId, 2);
    expect(picked?.isInProgress, isTrue);
  });

  test('selects backend eligible pending', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(id: 1, time: '09:48:00', status: 'pending', eligible: true),
      ],
    );
    expect(snapshot.isEligible, isTrue);
    expect(snapshot.selected?.dailyMedicationId, 1);
    expect(snapshot.message, 'Jadwal minum obat tersedia.');
  });

  test('overdue stays selectable when backend eligible is true', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(id: 1, time: '09:48:00', status: 'pending', eligible: true),
      ],
    );
    expect(picked?.dailyMedicationId, 1);
  });

  test('upcoming uses eligible false, not local clock', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(id: 1, time: '12:00:00', status: 'pending', eligible: false),
      ],
    );
    expect(snapshot.kind, VotScheduleKind.upcoming);
    expect(snapshot.selected, isNull);
    expect(snapshot.message, 'Jadwal minum obat berikutnya pukul 12:00.');
  });

  test('verified is not selectable', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(
          id: 1,
          time: '08:00:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
      ],
    );
    expect(snapshot.selected, isNull);
    expect(snapshot.kind, VotScheduleKind.finished);
    expect(snapshot.message, TodayMedicationPicker.allFinishedMessage());
  });

  test('verified A does not block eligible B', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(
          id: 1,
          time: '09:48:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
        _item(id: 2, time: '09:50:00', status: 'pending', eligible: true),
      ],
    );
    expect(picked?.dailyMedicationId, 2);
    expect(picked?.status, isNot('verified'));
  });

  test('after A verified, B becomes current if eligible', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(
          id: 1,
          time: '09:48:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
        _item(id: 2, time: '13:00:00', status: 'pending', eligible: true),
        _item(id: 3, time: '18:00:00', status: 'pending', eligible: false),
      ],
    );
    expect(snapshot.selected?.dailyMedicationId, 2);
    expect(snapshot.selected?.scheduledTime, '13:00:00');
  });

  test('refresh after complete uses new today list', () {
    final List<DailyMedication> afterComplete = <DailyMedication>[
      _item(
        id: 1,
        time: '09:48:00',
        status: 'verified',
        votStep: 'verified',
        eligible: false,
      ),
      _item(id: 2, time: '13:00:00', status: 'pending', eligible: true),
    ];
    expect(TodayMedicationPicker.pick(afterComplete)?.dailyMedicationId, 2);
  });

  test('Test Lagi does not pick verified medication', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(
          id: 1,
          time: '08:00:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
        _item(id: 2, time: '12:00:00', status: 'pending', eligible: true),
      ],
    );
    expect(picked?.dailyMedicationId, 2);
  });

  test('all verified is informational finished state', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(
          id: 1,
          time: '09:48:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
        _item(
          id: 2,
          time: '13:00:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
      ],
    );
    expect(snapshot.kind, VotScheduleKind.finished);
    expect(snapshot.selected, isNull);
    expect(snapshot.message, TodayMedicationPicker.allFinishedMessage());
  });

  test('local clock does not override backend eligible false', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      <DailyMedication>[
        _item(id: 1, time: '08:00:00', status: 'pending', eligible: false),
      ],
    );
    expect(snapshot.kind, VotScheduleKind.upcoming);
    expect(snapshot.selected, isNull);
  });

  test('home next after verified A is upcoming B today, not tomorrow', () {
    final DailyMedication? next = TodayMedicationPicker.homeNext(
      <DailyMedication>[
        _item(
          id: 1,
          time: '09:48:00',
          status: 'verified',
          votStep: 'verified',
          eligible: false,
        ),
        _item(id: 2, time: '13:00:00', status: 'pending', eligible: false),
      ],
    );
    expect(next?.dailyMedicationId, 2);
    expect(next?.scheduledTime, '13:00:00');
  });

  test('empty today list is empty state', () {
    final VotScheduleSnapshot snapshot = TodayMedicationPicker.inspect(
      const <DailyMedication>[],
    );
    expect(snapshot.kind, VotScheduleKind.empty);
    expect(snapshot.message, 'Hari ini tidak ada jadwal minum obat.');
  });

  test('complete contract still uses daily_medication_id from start', () {
    expect(
      VotFlow.completeRequestBody(19),
      <String, Object>{
        'daily_medication_id': 19,
        'drinking_verified': true,
      },
    );
  });

  test('watch interval stays in 45-60s and does not imply local eligible override',
      () {
    expect(
      TodayMedicationPicker.watchInterval.inSeconds,
      inInclusiveRange(45, 60),
    );
  });

  testWidgets('schedule info is not an error or reload UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VotScheduleInfo(
            message: 'Jadwal minum obat berikutnya pukul 12:00.',
          ),
        ),
      ),
    );

    expect(find.text('Jadwal minum obat berikutnya pukul 12:00.'), findsOneWidget);
    expect(find.text('Muat Ulang'), findsNothing);
    expect(find.text('Coba Lagi'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
