import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/daily_medication.dart';
import 'package:sitara/features/ai_vot/utils/today_medication_picker.dart';

DailyMedication _item({
  required int id,
  required String time,
  required String status,
  String votStep = 'waiting',
}) {
  return DailyMedication(
    dailyMedicationId: id,
    medicineScheduleId: id + 10,
    medicineId: 2,
    medicineName: 'Promag',
    dosage: '1 tablet',
    scheduledDate: '2026-08-26',
    scheduledTime: time,
    quantityRemaining: 30,
    status: status,
    votStep: votStep,
  );
}

void main() {
  test('parses GET /medications/today item', () {
    final DailyMedication item = DailyMedication.fromJson(<String, dynamic>{
      'daily_medication_id': 1,
      'medicine_schedule_id': 4,
      'medicine_id': 2,
      'medicine_name': 'Promag',
      'dosage': '1 tablet',
      'scheduled_date': '2026-08-26',
      'scheduled_time': '20:00:00',
      'quantity_remaining': 30,
      'status': 'pending',
      'vot_step': 'waiting',
    });

    expect(item.dailyMedicationId, 1);
    expect(item.medicineScheduleId, 4);
    expect(item.medicineName, 'Promag');
    expect(item.status, 'pending');
    expect(item.votStep, 'waiting');
    expect(item.scheduledMinutesOfDay, 20 * 60);
  });

  test('picks next pending by scheduled_time', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(id: 1, time: '08:00:00', status: 'pending'),
        _item(id: 2, time: '20:00:00', status: 'pending'),
      ],
      now: DateTime(2026, 8, 26, 12, 0),
    );
    expect(picked?.dailyMedicationId, 2);
  });

  test('prefers in_progress over pending', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(id: 1, time: '08:00:00', status: 'pending'),
        _item(
          id: 2,
          time: '20:00:00',
          status: 'in_progress',
          votStep: 'face_verified',
        ),
      ],
      now: DateTime(2026, 8, 26, 7, 0),
    );
    expect(picked?.dailyMedicationId, 2);
  });

  test('skips verified missed rejected', () {
    final DailyMedication? picked = TodayMedicationPicker.pick(
      <DailyMedication>[
        _item(id: 1, time: '08:00:00', status: 'verified'),
        _item(id: 2, time: '12:00:00', status: 'missed'),
        _item(id: 3, time: '20:00:00', status: 'rejected'),
      ],
      now: DateTime(2026, 8, 26, 9, 0),
    );
    expect(picked, isNull);
  });

  test('empty list returns null', () {
    expect(TodayMedicationPicker.pick(const <DailyMedication>[]), isNull);
  });
}
