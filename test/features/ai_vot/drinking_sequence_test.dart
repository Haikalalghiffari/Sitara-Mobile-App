import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/utils/drinking_sequence.dart';

void main() {
  test('near mouth alone does not complete', () {
    final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
      minDwell: Duration.zero,
    );
    final DateTime t0 = DateTime(2026, 8, 26, 12);

    machine.update(
      handVisible: true,
      faceVisible: true,
      handMouthDistance: 0.1,
      now: t0,
    );
    expect(machine.stage, isNot(DrinkingStage.completed));
  });

  test('full temporal sequence reaches completed', () {
    final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
      minDwell: Duration.zero,
      nearThreshold: 0.22,
      farThreshold: 0.34,
      approachDelta: 0.015,
    );

    DateTime now = DateTime(2026, 8, 26, 12);
    DrinkingStage tick(double distance) {
      now = now.add(const Duration(milliseconds: 50));
      return machine.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: distance,
        now: now,
      );
    }

    expect(tick(0.50), DrinkingStage.handWithMedicine);
    expect(tick(0.40), DrinkingStage.approachingMouth);
    expect(tick(0.18), DrinkingStage.nearMouth);
    expect(tick(0.28), DrinkingStage.withdrawing);
    expect(tick(0.40), DrinkingStage.completed);
  });
}
