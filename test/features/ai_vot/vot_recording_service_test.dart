import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/services/vot_recording_service.dart';

void main() {
  late VotRecordingService service;
  final List<File> tempFiles = <File>[];

  setUp(() {
    service = VotRecordingService();
  });

  tearDown(() async {
    for (final File file in tempFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }
    tempFiles.clear();
  });

  Future<File> nonEmptyVideo() async {
    final File file = File(
      '${Directory.systemTemp.path}/vot_one_video_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    await file.writeAsBytes(const <int>[0, 1, 2, 3, 4, 5]);
    tempFiles.add(file);
    return file;
  }

  group('VotRecordingService one-video lifecycle', () {
    test('1. initial state can start once', () {
      expect(service.status, VotRecordingStatus.idle);
      expect(service.isRecording, isFalse);
      expect(service.canStartRecording, isTrue);
      expect(service.recordedVideoPath, isNull);
      expect(service.isFileReady, isFalse);
    });

    test('2. duplicate start dicegah saat sudah recording', () async {
      service.debugMarkRecording();
      expect(service.isRecording, isTrue);

      final bool started = await service.startRecording(null);
      expect(started, isFalse);
      expect(service.isRecording, isTrue);
      expect(service.errorMessage, contains('sudah berjalan'));
    });

    test('2b. duplicate start dicegah jika file sesi sudah ada', () async {
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);

      final bool started = await service.startRecording(null);
      expect(started, isFalse);
      expect(service.recordedVideoPath, file.path);
      expect(service.isFileReady, isTrue);
      expect(service.status, VotRecordingStatus.completed);
    });

    test('3-5. stop mengunci path, file exists, size > 0', () async {
      final File file = await nonEmptyVideo();
      service.debugMarkRecording();
      service.debugAdoptFinalFile(file.path);

      final validation = await service.validateRecordedFile();
      expect(validation.isValid, isTrue);
      expect(validation.path, file.path);
      expect(await file.exists(), isTrue);
      expect(validation.bytes, greaterThan(0));
      expect(service.recordedVideoPath, file.path);
    });

    test('6. stop without start ditangani aman', () async {
      final file = await service.stopRecording(null);
      expect(file, isNull);
      expect(service.status, VotRecordingStatus.idle);
      expect(service.isRecording, isFalse);
    });

    test('7. setelah stop, isRecording false dan status bukan recording', () async {
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);

      expect(service.isRecording, isFalse);
      expect(service.status, VotRecordingStatus.completed);
      await service.stopRecording(null);
      expect(service.isRecording, isFalse);
      expect(service.status, VotRecordingStatus.completed);
    });

    test('8. recordedVideoPath tetap tersedia setelah stop', () async {
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);

      await service.stopRecording(null);
      expect(service.recordedVideoPath, file.path);
      expect(service.isFileReady, isTrue);
    });

    test('9. cleanup tidak terjadi otomatis setelah stop', () async {
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);

      await service.stopRecording(null);
      expect(await file.exists(), isTrue);
      expect(service.recordedVideoPath, file.path);
      expect(service.hasSessionFile, isTrue);
    });

    test('10. recording lifecycle tidak bergantung image stream', () async {
      expect(service.canStartRecording, isTrue);
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);
      final VotVideoValidation validation = await service.validateRecordedFile();
      expect(validation.isValid, isTrue);
      expect(service.canStartRecording, isFalse);
    });

    test('validatePath menolak file kosong', () async {
      final File file = File(
        '${Directory.systemTemp.path}/vot_empty_${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(const <int>[]);
      tempFiles.add(file);

      final VotVideoValidation validation =
          await VotRecordingService.validatePath(file.path);
      expect(validation.isValid, isFalse);
      expect(validation.bytes, 0);
    });

    test('validatePath menolak path hilang', () async {
      final VotVideoValidation validation =
          await VotRecordingService.validatePath(
        '${Directory.systemTemp.path}/vot_missing_no_file.mp4',
      );
      expect(validation.isValid, isFalse);
    });

    test('start kamera null menandai failed tanpa path sesi', () async {
      final bool started = await service.startRecording(null);
      expect(started, isFalse);
      expect(service.status, VotRecordingStatus.failed);
      expect(service.hasSessionFile, isFalse);
      expect(service.canStartRecording, isTrue);
      expect(service.errorMessage, isNotNull);
    });

    test('cleanup hanya menghapus ketika dipanggil eksplisit', () async {
      final File file = await nonEmptyVideo();
      service.debugAdoptFinalFile(file.path);
      await service.stopRecording(null);
      expect(await file.exists(), isTrue);

      await service.cleanUpTemporaryVideo();
      expect(await file.exists(), isFalse);
      expect(service.recordedVideoPath, isNull);
      expect(service.status, VotRecordingStatus.idle);
      expect(service.canStartRecording, isTrue);
    });
  });
}
