import 'package:flutter/services.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum VotRecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  uploading,
  completed,
  failed,
}

/// Service untuk mengelola siklus hidup perekaman video otomatis AI VOT.
class VotRecordingService {
  VotRecordingStatus _status = VotRecordingStatus.idle;
  String? _recordedVideoPath;
  XFile? _recordedVideoFile;
  String? _errorMessage;

  VotRecordingStatus get status => _status;
  bool get isRecording => _status == VotRecordingStatus.recording;
  String? get recordedVideoPath => _recordedVideoPath;
  XFile? get recordedVideoFile => _recordedVideoFile;
  String? get errorMessage => _errorMessage;

  /// Memulai perekaman video secara otomatis dari CameraController.
  Future<bool> startRecording(CameraController? controller) async {
    if (_status == VotRecordingStatus.recording ||
        _status == VotRecordingStatus.starting) {
      return false;
    }

    if (controller == null || !controller.value.isInitialized) {
      _status = VotRecordingStatus.failed;
      _errorMessage = 'Kamera belum siap untuk merekam video.';
      return false;
    }

    if (controller.value.isRecordingVideo) {
      _status = VotRecordingStatus.recording;
      return true;
    }

    _status = VotRecordingStatus.starting;
    _errorMessage = null;

    try {
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      await controller.startVideoRecording();
      _status = VotRecordingStatus.recording;
      return true;
    } catch (e) {
      _status = VotRecordingStatus.failed;
      _errorMessage = e.toString();
      debugPrint('[VotRecordingService] Gagal start recording: ');
      return false;
    }
  }

  /// Menghentikan perekaman video dan menyimpan reference file.
  Future<XFile?> stopRecording(CameraController? controller) async {
    if (_status != VotRecordingStatus.recording &&
        _status != VotRecordingStatus.starting) {
      return _recordedVideoFile;
    }

    _status = VotRecordingStatus.stopping;

    if (controller == null || !controller.value.isInitialized) {
      _status = VotRecordingStatus.failed;
      return null;
    }

    try {
      if (controller.value.isRecordingVideo) {
        final XFile file = await controller.stopVideoRecording();
        _recordedVideoFile = file;
        _recordedVideoPath = file.path;
        _status = VotRecordingStatus.completed;
        return file;
      } else {
        _status = VotRecordingStatus.completed;
        return _recordedVideoFile;
      }
    } catch (e) {
      _status = VotRecordingStatus.failed;
      _errorMessage = e.toString();
      debugPrint('[VotRecordingService] Gagal stop recording: ');
      return null;
    }
  }

  /// Membersihkan file video temporary setelah selesai/diunggah.
  Future<void> cleanUpTemporaryVideo() async {
    final String? path = _recordedVideoPath;
    if (path != null && path.isNotEmpty) {
      try {
        final File file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[VotRecordingService] Gagal menghapus temporary video: ');
      }
    }
    _recordedVideoFile = null;
    _recordedVideoPath = null;
  }

  /// Reset state service.
  void reset() {
    _status = VotRecordingStatus.idle;
    _errorMessage = null;
  }
}
