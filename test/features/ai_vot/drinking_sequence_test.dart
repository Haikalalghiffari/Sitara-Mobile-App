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

  group('DrinkingSequenceMachine maxStageReached', () {
    test('Test A: waiting -> handWithMedicine -> nearMouth -> tracking lost retains nearMouth in maxStageReached', () {
      final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
        minDwell: Duration.zero,
      );
      DateTime now = DateTime(2026, 8, 26, 12);

      // 1. handWithMedicine
      now = now.add(const Duration(milliseconds: 50));
      machine.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.50,
        now: now,
      );
      expect(machine.stage, DrinkingStage.handWithMedicine);
      expect(machine.maxStageReached, DrinkingStage.handWithMedicine);

      // 2. approachingMouth
      now = now.add(const Duration(milliseconds: 50));
      machine.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.40,
        now: now,
      );
      expect(machine.stage, DrinkingStage.approachingMouth);
      expect(machine.maxStageReached, DrinkingStage.approachingMouth);

      // 3. nearMouth
      now = now.add(const Duration(milliseconds: 50));
      machine.update(
        handVisible: true,
        faceVisible: true,
        handMouthDistance: 0.18,
        now: now,
      );
      expect(machine.stage, DrinkingStage.nearMouth);
      expect(machine.maxStageReached, DrinkingStage.nearMouth);

      // 4. Tracking lost (hand not visible) -> fallback to waiting
      now = now.add(const Duration(milliseconds: 50));
      machine.update(
        handVisible: false,
        faceVisible: true,
        handMouthDistance: null,
        now: now,
      );
      expect(machine.stage, DrinkingStage.nearMouth);
      expect(machine.maxStageReached, DrinkingStage.nearMouth);
    });

    test('Test B: waiting -> nearMouth -> withdrawing -> tracking lost retains withdrawing', () {
      final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
        minDwell: Duration.zero,
      );
      DateTime now = DateTime(2026, 8, 26, 12);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.50, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.40, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.18, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.28, now: now);
      expect(machine.stage, DrinkingStage.withdrawing);
      expect(machine.maxStageReached, DrinkingStage.withdrawing);

      // Tracking lost
      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: false, faceVisible: false, handMouthDistance: null, now: now);
      expect(machine.maxStageReached, DrinkingStage.withdrawing);
    });

    test('Test C: waiting -> nearMouth -> withdrawing -> completed reaches completed', () {
      final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
        minDwell: Duration.zero,
      );
      DateTime now = DateTime(2026, 8, 26, 12);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.50, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.40, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.18, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.28, now: now);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.40, now: now);
      expect(machine.stage, DrinkingStage.completed);
      expect(machine.maxStageReached, DrinkingStage.completed);
    });

    test('Test D: reset restores maxStageReached to waiting', () {
      final DrinkingSequenceMachine machine = DrinkingSequenceMachine(
        minDwell: Duration.zero,
      );
      DateTime now = DateTime(2026, 8, 26, 12);

      now = now.add(const Duration(milliseconds: 50));
      machine.update(handVisible: true, faceVisible: true, handMouthDistance: 0.50, now: now);
      expect(machine.maxStageReached, DrinkingStage.handWithMedicine);

      machine.reset();
      expect(machine.stage, DrinkingStage.waiting);
      expect(machine.maxStageReached, DrinkingStage.waiting);
    });
  });
}
