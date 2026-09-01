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
      nearThreshold: DrinkingSequenceConfig.nearThreshold,
      farThreshold: DrinkingSequenceConfig.farThreshold,
      approachDelta: DrinkingSequenceConfig.approachDelta,
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

  test('slow withdraw after near mouth still completes', () {
    final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
      minDwell: Duration.zero,
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
    expect(tick(0.30), DrinkingStage.approachingMouth);
    expect(tick(0.18), DrinkingStage.nearMouth);
    // Delta 0.011 < approachDelta 0.015; cukup keluar zona near.
    expect(tick(0.231), DrinkingStage.withdrawing);
    expect(tick(0.36), DrinkingStage.completed);
  });

  test('default dwell needs a following frame, not a single frame', () {
    final DrinkingSequenceMachine machine = DrinkingSequenceMachine();
    DateTime now = DateTime(2026, 8, 26, 12);

    machine.update(
      handVisible: true,
      faceVisible: true,
      handMouthDistance: 0.50,
      now: now,
    );
    expect(machine.stage, DrinkingStage.handWithMedicine);

    now = now.add(const Duration(milliseconds: 50));
    machine.update(
      handVisible: true,
      faceVisible: true,
      handMouthDistance: 0.18,
      now: now,
    );
    expect(machine.stage, DrinkingStage.handWithMedicine);

    now = now.add(DrinkingSequenceConfig.minDwell);
    machine.update(
      handVisible: true,
      faceVisible: true,
      handMouthDistance: 0.18,
      now: now,
    );
    expect(machine.stage, isNot(DrinkingStage.waiting));
    expect(machine.stage, isNot(DrinkingStage.completed));
  });

  test('timeout is true only after configured window', () {
    final DateTime start = DateTime(2026, 8, 26, 12);
    expect(
      DrinkingSequenceMachine.hasTimedOut(
        startedAt: start,
        now: start.add(const Duration(seconds: 19)),
      ),
      isFalse,
    );
    expect(
      DrinkingSequenceMachine.hasTimedOut(
        startedAt: start,
        now: start.add(DrinkingSequenceConfig.timeout),
      ),
      isTrue,
    );
    expect(
      DrinkingSequenceMachine.hasTimedOut(
        startedAt: null,
        now: start.add(DrinkingSequenceConfig.timeout),
      ),
      isFalse,
    );
  });
}
