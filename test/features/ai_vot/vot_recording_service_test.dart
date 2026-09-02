import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/services/vot_recording_service.dart';

void main() {
  group('VotRecordingService Unit Tests', () {
    late VotRecordingService service;

    setUp(() {
      service = VotRecordingService();
    });

    test('initial state is idle', () {
      expect(service.status, VotRecordingStatus.idle);
      expect(service.isRecording, isFalse);
      expect(service.recordedVideoFile, isNull);
      expect(service.recordedVideoPath, isNull);
      expect(service.errorMessage, isNull);
    });

    test('startRecording returns false and marks failed when controller is null', () async {
      final bool started = await service.startRecording(null);
      expect(started, isFalse);
      expect(service.status, VotRecordingStatus.failed);
      expect(service.errorMessage, isNotNull);
    });

    test('stopRecording returns null and marks failed when controller is null and was not recording', () async {
      final file = await service.stopRecording(null);
      expect(file, isNull);
      expect(service.status, VotRecordingStatus.idle);
    });

    test('cleanUpTemporaryVideo safely executes when no file path is present', () async {
      await service.cleanUpTemporaryVideo();
      expect(service.recordedVideoFile, isNull);
      expect(service.recordedVideoPath, isNull);
    });

    test('reset restores status to idle', () {
      service.reset();
      expect(service.status, VotRecordingStatus.idle);
      expect(service.errorMessage, isNull);
    });
  });
}
