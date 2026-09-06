/// Tahap lokal verifikasi visual minum. Bukan status server.
enum DrinkingStage {
  waiting,
  handWithMedicine,
  approachingMouth,
  nearMouth,
  withdrawing,
  completed,
}

/// Ambang temporal sequence minum.
class DrinkingSequenceConfig {
  const DrinkingSequenceConfig._();

  static const double nearThreshold = 0.22;
  static const double farThreshold = 0.34;
  static const double approachDelta = 0.015;
  static const Duration minDwell = Duration(milliseconds: 120);
  static const Duration timeout = Duration(seconds: 20);
  static const String timeoutMessage =
      'Verifikasi minum belum terdeteksi. Silakan coba lagi.';
}

/// Mesin state temporal: dekat mulut saja tidak cukup untuk completed.
class DrinkingSequenceMachine {
  DrinkingSequenceMachine({
    this.nearThreshold = DrinkingSequenceConfig.nearThreshold,
    this.farThreshold = DrinkingSequenceConfig.farThreshold,
    this.approachDelta = DrinkingSequenceConfig.approachDelta,
    this.minDwell = DrinkingSequenceConfig.minDwell,
  });

  final double nearThreshold;
  final double farThreshold;
  final double approachDelta;
  final Duration minDwell;

  DrinkingStage stage = DrinkingStage.waiting;
  DrinkingStage maxStageReached = DrinkingStage.waiting;
  double? _lastDistance;
  DateTime? _enteredAt;

  void reset() {
    stage = DrinkingStage.waiting;
    maxStageReached = DrinkingStage.waiting;
    _lastDistance = null;
    _enteredAt = null;
  }

  static bool hasTimedOut({
    required DateTime? startedAt,
    required DateTime now,
    Duration timeout = DrinkingSequenceConfig.timeout,
  }) {
    if (startedAt == null) return false;
    return now.difference(startedAt) >= timeout;
  }

  /// [faceLostWithinGrace] berasal dari `VotIdentityLock`: wajah sedang tidak
  /// terlihat, tetapi masih di dalam masa tenggang.
  ///
  /// Selama masa tenggang, wajah yang hilang tidak menurunkan tahap. Bila
  /// jarak tangan ke mulut masih terbaca (mulut dari memori jangka pendek
  /// milik LocalDrinkingService), urutan minum tetap diproses seperti biasa;
  /// bila tidak, tahap saat ini ditahan. Menunduk, menoleh, tangan menutupi
  /// wajah, dan motion blur karena itu tidak membatalkan urutan minum.
  DrinkingStage update({
    required bool handVisible,
    required bool faceVisible,
    required double? handMouthDistance,
    required DateTime now,
    bool faceLostWithinGrace = false,
  }) {
    if (stage == DrinkingStage.completed) return stage;

    final bool toleratedFaceLoss = !faceVisible && faceLostWithinGrace;
    final double? measured = handVisible ? handMouthDistance : null;

    if (measured == null || (!faceVisible && !toleratedFaceLoss)) {
      // Wajah hilang sesaat tanpa geometri: tahan tahap, jangan turunkan.
      if (toleratedFaceLoss) return stage;

      if (stage == DrinkingStage.waiting ||
          stage == DrinkingStage.handWithMedicine) {
        _setStage(DrinkingStage.waiting, now);
      }
      _lastDistance = handMouthDistance;
      return stage;
    }

    final double distance = measured;
    final double? previous = _lastDistance;
    _lastDistance = distance;
    final bool dwellOk =
        _enteredAt != null && now.difference(_enteredAt!) >= minDwell;

    switch (stage) {
      case DrinkingStage.waiting:
        _setStage(DrinkingStage.handWithMedicine, now);
        break;
      case DrinkingStage.handWithMedicine:
        if (dwellOk && _isApproaching(distance, previous)) {
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
        // Keluar zona mulut setelah dwell, tanpa menuntut delta per-frame
        // yang besar (gerakan pelan sering < approachDelta).
        if (dwellOk && distance > nearThreshold) {
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

  bool _isApproaching(double distance, double? previous) {
    if (distance <= farThreshold) return true;
    return previous != null && previous - distance >= approachDelta;
  }

  void _setStage(DrinkingStage next, DateTime now) {
    if (next.index > maxStageReached.index) {
      maxStageReached = next;
    }
    if (stage == next) return;
    stage = next;
    _enteredAt = now;
  }
}
