import 'dart:math' as math;

class VotSessionDiagnostic {
  int attempt = 1;
  DateTime? sessionStart;
  DateTime? sessionEnd;
  
  int totalFrames = 0;
  int faceDetectedCount = 0;
  int noFaceCount = 0;
  int handDetectedCount = 0;
  int noHandCount = 0;
  int nullDistanceCount = 0;
  
  double? firstDistance;
  double? lastDistance;
  double? minDistance;
  double? maxDistance;
  
  bool nearThresholdReached = false;
  bool farThresholdReached = false;
  bool farReachedAfterNear = false;

  final double nearThreshold;
  final double farThreshold;

  VotSessionDiagnostic({
    this.nearThreshold = 0.22,
    this.farThreshold = 0.34,
  });

  void reset(int attemptNumber) {
    attempt = attemptNumber;
    sessionStart = DateTime.now();
    sessionEnd = null;
    totalFrames = 0;
    faceDetectedCount = 0;
    noFaceCount = 0;
    handDetectedCount = 0;
    noHandCount = 0;
    nullDistanceCount = 0;
    firstDistance = null;
    lastDistance = null;
    minDistance = null;
    maxDistance = null;
    nearThresholdReached = false;
    farThresholdReached = false;
    farReachedAfterNear = false;
  }

  void recordFrame({
    required bool faceVisible,
    required bool handVisible,
    required double? distance,
  }) {
    totalFrames++;
    if (faceVisible) {
      faceDetectedCount++;
    } else {
      noFaceCount++;
    }
    
    if (handVisible) {
      handDetectedCount++;
    } else {
      noHandCount++;
    }

    if (distance == null) {
      nullDistanceCount++;
    } else {
      firstDistance ??= distance;
      lastDistance = distance;
      
      minDistance = minDistance == null ? distance : math.min(minDistance!, distance);
      maxDistance = maxDistance == null ? distance : math.max(maxDistance!, distance);

      if (distance <= nearThreshold) {
        nearThresholdReached = true;
      }
      
      if (distance >= farThreshold) {
        farThresholdReached = true;
        if (nearThresholdReached) {
          farReachedAfterNear = true;
        }
      }
    }
  }

  void printSummary({
    required String currentState,
    required String maxStateReached,
    required bool sequenceCompleted,
    required bool streamActive,
    required bool videoRecording,
  }) {
    sessionEnd = DateTime.now();
    final int durationSecs = sessionStart != null 
        ? sessionEnd!.difference(sessionStart!).inSeconds 
        : 0;

    // ignore: avoid_print
    print('\n========================================'
        '\n[VOT SESSION DIAGNOSTIC]'
        '\n========================================'
        '\nATTEMPT: $attempt'
        '\nDURATION: ${durationSecs}s'
        '\nFRAMES: $totalFrames'
        '\nFACE: $faceDetectedCount / NO: $noFaceCount'
        '\nHAND: $handDetectedCount / NO: $noHandCount'
        '\nNULL DIST: $nullDistanceCount'
        '\nMIN: ${minDistance?.toStringAsFixed(3) ?? "null"}'
        '\nMAX: ${maxDistance?.toStringAsFixed(3) ?? "null"}'
        '\nNEAR REACHED: ${nearThresholdReached ? "YES" : "NO"}'
        '\nFAR REACHED: ${farThresholdReached ? "YES" : "NO"}'
        '\nFAR AFTER NEAR: ${farReachedAfterNear ? "YES" : "NO"}'
        '\nSTATE: $currentState'
        '\nMAX STATE: $maxStateReached'
        '\nCOMPLETED: ${sequenceCompleted ? "YES" : "NO"}'
        '\n========================================\n');
  }
}
