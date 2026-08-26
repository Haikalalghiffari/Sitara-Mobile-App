/// Tahap lokal verifikasi visual minum. Bukan status server.
enum DrinkingStage {
  waiting,
  handWithMedicine,
  approachingMouth,
  nearMouth,
  withdrawing,
  completed,
}

/// Mesin state temporal: dekat mulut saja tidak cukup untuk completed.
class DrinkingSequenceMachine {
  DrinkingSequenceMachine({
    this.nearThreshold = 0.22,
    this.farThreshold = 0.34,
    this.approachDelta = 0.015,
    this.minDwell = const Duration(milliseconds: 280),
  });

  final double nearThreshold;
  final double farThreshold;
  final double approachDelta;
  final Duration minDwell;

  DrinkingStage stage = DrinkingStage.waiting;
  double? _lastDistance;
  DateTime? _enteredAt;

  void reset() {
    stage = DrinkingStage.waiting;
    _lastDistance = null;
    _enteredAt = null;
  }

  DrinkingStage update({
    required bool handVisible,
    required bool faceVisible,
    required double? handMouthDistance,
    required DateTime now,
  }) {
    if (stage == DrinkingStage.completed) return stage;

    if (!handVisible || !faceVisible || handMouthDistance == null) {
      if (stage == DrinkingStage.waiting ||
          stage == DrinkingStage.handWithMedicine) {
        _setStage(DrinkingStage.waiting, now);
      }
      _lastDistance = handMouthDistance;
      return stage;
    }

    final double distance = handMouthDistance;
    final double? previous = _lastDistance;
    _lastDistance = distance;
    final bool dwellOk =
        _enteredAt != null && now.difference(_enteredAt!) >= minDwell;

    switch (stage) {
      case DrinkingStage.waiting:
        _setStage(DrinkingStage.handWithMedicine, now);
        break;
      case DrinkingStage.handWithMedicine:
        if (dwellOk &&
            previous != null &&
            previous - distance >= approachDelta) {
          _setStage(DrinkingStage.approachingMouth, now);
        }
        break;
      case DrinkingStage.approachingMouth:
        if (distance <= nearThreshold && dwellOk) {
          _setStage(DrinkingStage.nearMouth, now);
        } else if (previous != null &&
            distance - previous >= approachDelta &&
            distance > farThreshold) {
          _setStage(DrinkingStage.handWithMedicine, now);
        }
        break;
      case DrinkingStage.nearMouth:
        if (dwellOk &&
            previous != null &&
            distance - previous >= approachDelta &&
            distance > nearThreshold) {
          _setStage(DrinkingStage.withdrawing, now);
        }
        break;
      case DrinkingStage.withdrawing:
        if (dwellOk && distance >= farThreshold) {
          _setStage(DrinkingStage.completed, now);
        } else if (distance <= nearThreshold) {
          _setStage(DrinkingStage.nearMouth, now);
        }
        break;
      case DrinkingStage.completed:
        break;
    }

    return stage;
  }

  void _setStage(DrinkingStage next, DateTime now) {
    if (stage == next) return;
    stage = next;
    _enteredAt = now;
  }
}
