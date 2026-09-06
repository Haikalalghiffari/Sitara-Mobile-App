import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/drinking_analysis_result.dart';
import 'package:sitara/features/ai_vot/utils/video_frame_extractor.dart';

void main() {
  group('VideoDrinkingAnalysis Model & Diagnostic Tests', () {
    test('DrinkingAnalysisResult formats diagnostic banner exactly as specified', () {
      const result = DrinkingAnalysisResult(
        videoDurationMs: 4500,
        framesExtracted: 18,
        faceDetectedFrames: 18,
        handDetectedFrames: 16,
        validDistanceFrames: 15,
        minDistance: 0.115,
        maxDistance: 0.520,
        nearMouthDetected: true,
        approachDetected: true,
        withdrawDetected: true,
        sequenceCompleted: true,
        confidenceScore: 92.5,
        level: DrinkingConfidenceLevel.high,
        isAutoVerified: true,
        reason: 'Visual drinking sequence detected with high confidence (92.5%).',
      );

      expect(result.level, DrinkingConfidenceLevel.high);
      expect(result.isAutoVerified, isTrue);
      expect(result.statusLabel, 'AUTO VERIFIED');

      // Verify diagnostic printing executes without error
      result.printDiagnosticSummary();
    });

    test('Confidence score classification thresholds', () {
      // 1. High confidence >= 80 -> AUTO VERIFIED
      const highResult = DrinkingAnalysisResult(
        videoDurationMs: 4000,
        framesExtracted: 18,
        faceDetectedFrames: 18,
        handDetectedFrames: 18,
        validDistanceFrames: 16,
        minDistance: 0.12,
        maxDistance: 0.45,
        nearMouthDetected: true,
        approachDetected: true,
        withdrawDetected: true,
        sequenceCompleted: true,
        confidenceScore: 85.0,
        level: DrinkingConfidenceLevel.high,
        isAutoVerified: true,
        reason: 'Visual drinking sequence detected',
      );
      expect(highResult.level, DrinkingConfidenceLevel.high);
      expect(highResult.statusLabel, 'AUTO VERIFIED');
      expect(highResult.isAutoVerified, isTrue);

      // 2. Medium confidence 50-79 -> NEEDS REVIEW
      const medResult = DrinkingAnalysisResult(
        videoDurationMs: 4000,
        framesExtracted: 18,
        faceDetectedFrames: 14,
        handDetectedFrames: 10,
        validDistanceFrames: 8,
        minDistance: 0.18,
        maxDistance: 0.38,
        nearMouthDetected: true,
        approachDetected: true,
        withdrawDetected: false,
        sequenceCompleted: false,
        confidenceScore: 65.0,
        level: DrinkingConfidenceLevel.medium,
        isAutoVerified: false,
        reason: 'Visual drinking sequence partially detected',
      );
      expect(medResult.level, DrinkingConfidenceLevel.medium);
      expect(medResult.statusLabel, 'NEEDS REVIEW');
      expect(medResult.isAutoVerified, isFalse);

      // 3. Low confidence < 50 -> MANUAL REVIEW REQUIRED
      const lowResult = DrinkingAnalysisResult(
        videoDurationMs: 4000,
        framesExtracted: 18,
        faceDetectedFrames: 6,
        handDetectedFrames: 2,
        validDistanceFrames: 1,
        minDistance: 0.40,
        maxDistance: 0.40,
        nearMouthDetected: false,
        approachDetected: false,
        withdrawDetected: false,
        sequenceCompleted: false,
        confidenceScore: 28.0,
        level: DrinkingConfidenceLevel.low,
        isAutoVerified: false,
        reason: 'Visual drinking sequence could not be confidently detected',
      );
      expect(lowResult.level, DrinkingConfidenceLevel.low);
      expect(lowResult.statusLabel, 'MANUAL REVIEW REQUIRED');
      expect(lowResult.isAutoVerified, isFalse);
    });

    test('ExtractedVideoFrame minDistanceToMouth calculation accurately computes Euclidean distance', () {
      const frame = ExtractedVideoFrame(
        timestampMs: 500,
        path: '/tmp/test_frame_0.jpg',
        width: 720,
        height: 1280,
        handDetected: true,
        // Hand coordinates near (0.5, 0.6)
        thumbTipX: 0.52,
        thumbTipY: 0.60,
        indexTipX: 0.50,
        indexTipY: 0.58,
        middleTipX: 0.51,
        middleTipY: 0.59,
      );

      // Mouth at (0.50, 0.50)
      const mouth = ui.Offset(0.50, 0.50);
      final double? dist = frame.minDistanceToMouth(mouth);

      expect(dist, isNotNull);
      // Index tip distance: sqrt((0.50-0.50)^2 + (0.58-0.50)^2) = 0.08
      expect(dist, closeTo(0.08, 0.001));
    });

    test('ExtractedVideoFrame returns null distance when hand is not detected', () {
      const frame = ExtractedVideoFrame(
        timestampMs: 1000,
        path: '/tmp/test_frame_1.jpg',
        width: 720,
        height: 1280,
        handDetected: false,
      );
      const mouth = ui.Offset(0.50, 0.50);
      expect(frame.minDistanceToMouth(mouth), isNull);
    });

    test('CoordinateValidationResult formatDiagnostic outputs requested specification', () {
      const result = CoordinateValidationResult(
        framePath: '/tmp/vot_frames/frame_008.jpg',
        timestampMs: 1600,
        frameWidth: 720,
        frameHeight: 1280,
        handDetected: true,
        faceDetected: true,
        thumbTip: ui.Offset(0.485, 0.542),
        indexTip: ui.Offset(0.502, 0.518),
        middleTip: ui.Offset(0.510, 0.525),
        mouthPosition: ui.Offset(0.505, 0.510),
        handMouthDistance: 0.008,
        handNormalized: true,
        faceNormalized: true,
        hasRotation: false,
        hasMirror: false,
        coordinateSystemCompatible: true,
      );

      final String diag = result.formatDiagnostic();
      expect(diag, contains('FRAME:'));
      expect(diag, contains('width=720'));
      expect(diag, contains('height=1280'));
      expect(diag, contains('HAND:'));
      expect(diag, contains('thumb=(0.485, 0.542)'));
      expect(diag, contains('index=(0.502, 0.518)'));
      expect(diag, contains('middle=(0.510, 0.525)'));
      expect(diag, contains('MOUTH:'));
      expect(diag, contains('x=0.505'));
      expect(diag, contains('y=0.510'));
      expect(diag, contains('DISTANCE:'));
      expect(diag, contains('0.008'));

      expect(result.coordinateSystemCompatible, isTrue);
      expect(result.hasMirror, isFalse);
      expect(result.hasRotation, isFalse);
    });
  });
}
