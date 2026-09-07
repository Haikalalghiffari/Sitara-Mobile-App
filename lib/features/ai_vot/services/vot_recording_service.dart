import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum VotRecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  uploading,
  completed,
  failed,
}

/// Hasil cek file video drinking, tanpa decoder.
class VotVideoValidation {
  const VotVideoValidation({
    required this.isValid,
    required this.bytes,
    this.path,
    this.errorMessage,
  });

  final bool isValid;
  final int bytes;
  final String? path;
  final String? errorMessage;
}

/// Satu sesi drinking = satu file video.
///
/// `startRecording` hanya boleh berhasil sekali sampai [cleanUpTemporaryVideo].
/// `stopRecording` mengunci path; file tidak dihapus di sini.
class VotRecordingService {
  VotRecordingStatus _status = VotRecordingStatus.idle;
  String? _recordedVideoPath;
  XFile? _recordedVideoFile;
  String? _errorMessage;
  bool _fileReady = false;

  VotRecordingStatus get status => _status;
  bool get isRecording =>
      _status == VotRecordingStatus.recording ||
      _status == VotRecordingStatus.starting;
  String? get recordedVideoPath => _recordedVideoPath;
  XFile? get recordedVideoFile => _recordedVideoFile;
  String? get errorMessage => _errorMessage;
  bool get isFileReady => _fileReady;

  /// File sesi ini sudah pernah dihasilkan (valid atau tidak).
  bool get hasSessionFile =>
      _recordedVideoPath != null && _recordedVideoPath!.isNotEmpty;

  bool get canStartRecording => !isRecording && !hasSessionFile;

  /// Memulai satu recording. Ditolak jika sudah merekam atau file sesi ada.
  Future<bool> startRecording(CameraController? controller) async {
    if (isRecording) {
      _errorMessage = 'Perekaman sudah berjalan.';
      debugPrint('[VotRecordingService] start ditolak: sudah merekam.');
      return false;
    }

    if (hasSessionFile) {
      _errorMessage = 'Sesi drinking sudah memiliki satu video.';
      debugPrint(
        '[VotRecordingService] start ditolak: file sesi sudah ada di '
        '$_recordedVideoPath',
      );
      return false;
    }

    if (controller == null || !controller.value.isInitialized) {
      _status = VotRecordingStatus.failed;
      _errorMessage = 'Kamera belum siap untuk merekam video.';
      debugPrint('[VotRecordingService] start gagal: kamera belum siap.');
      return false;
    }

    if (controller.value.isRecordingVideo) {
      _status = VotRecordingStatus.recording;
      _errorMessage = null;
      return true;
    }

    _status = VotRecordingStatus.starting;
    _errorMessage = null;
    _fileReady = false;

    try {
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (error, stack) {
        debugPrint(
          '[VotRecordingService] lockCaptureOrientation: $error\n$stack',
        );
      }
      await controller.startVideoRecording();
      _status = VotRecordingStatus.recording;
      return true;
    } catch (error, stack) {
      _status = VotRecordingStatus.failed;
      _errorMessage = 'Gagal memulai perekaman: $error';
      debugPrint('[VotRecordingService] Gagal start recording: $error\n$stack');
      return false;
    }
  }

  /// Menghentikan recording dan mengunci path. Tidak menghapus file.
  Future<XFile?> stopRecording(CameraController? controller) async {
    if (!isRecording) {
      return _recordedVideoFile;
    }

    _status = VotRecordingStatus.stopping;

    if (controller == null || !controller.value.isInitialized) {
      _status = VotRecordingStatus.failed;
      _errorMessage = 'Kamera tidak siap saat menghentikan perekaman.';
      debugPrint('[VotRecordingService] stop gagal: kamera tidak siap.');
      return _recordedVideoFile;
    }

    try {
      if (controller.value.isRecordingVideo) {
        final XFile file = await controller.stopVideoRecording();
        _recordedVideoFile = file;
        _recordedVideoPath = file.path;
      }

      final VotVideoValidation validation = await validateRecordedFile();
      if (validation.isValid) {
        _status = VotRecordingStatus.completed;
        _fileReady = true;
        _errorMessage = null;
      } else {
        _status = VotRecordingStatus.failed;
        _fileReady = false;
        _errorMessage = validation.errorMessage;
        debugPrint(
          '[VotRecordingService] stop: file tidak valid: '
          '${validation.errorMessage}',
        );
      }
      return _recordedVideoFile;
    } catch (error, stack) {
      _status = VotRecordingStatus.failed;
      _fileReady = false;
      _errorMessage = 'Gagal menghentikan perekaman: $error';
      debugPrint('[VotRecordingService] Gagal stop recording: $error\n$stack');
      return _recordedVideoFile;
    }
  }

  Future<VotVideoValidation> validateRecordedFile() {
    return validatePath(_recordedVideoPath);
  }

  static Future<VotVideoValidation> validatePath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return const VotVideoValidation(
        isValid: false,
        bytes: 0,
        errorMessage: 'Path video kosong.',
      );
    }

    try {
      final File file = File(path);
      if (!await file.exists()) {
        return VotVideoValidation(
          isValid: false,
          path: path,
          bytes: 0,
          errorMessage: 'File video tidak ditemukan.',
        );
      }

      final int bytes = await file.length();
      if (bytes <= 0) {
        return VotVideoValidation(
          isValid: false,
          path: path,
          bytes: bytes,
          errorMessage: 'File video kosong.',
        );
      }

      return VotVideoValidation(
        isValid: true,
        path: path,
        bytes: bytes,
      );
    } catch (error, stack) {
      debugPrint('[VotRecordingService] validatePath: $error\n$stack');
      return VotVideoValidation(
        isValid: false,
        path: path,
        bytes: 0,
        errorMessage: 'File video tidak dapat dibaca: $error',
      );
    }
  }

  /// Hapus file hanya jika sesi benar-benar dibuang.
  Future<void> cleanUpTemporaryVideo() async {
    final String? path = _recordedVideoPath;
    if (path != null && path.isNotEmpty) {
      try {
        final File file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (error, stack) {
        debugPrint(
          '[VotRecordingService] Gagal menghapus temporary video: $error\n$stack',
        );
      }
    }
    _recordedVideoFile = null;
    _recordedVideoPath = null;
    _fileReady = false;
    _status = VotRecordingStatus.idle;
    _errorMessage = null;
  }

  void reset() {
    _status = VotRecordingStatus.idle;
    _errorMessage = null;
  }

  @visibleForTesting
  void debugMarkRecording() {
    _status = VotRecordingStatus.recording;
    _errorMessage = null;
  }

  @visibleForTesting
  void debugAdoptFinalFile(String path, {bool fileReady = true}) {
    _recordedVideoPath = path;
    _recordedVideoFile = XFile(path);
    _fileReady = fileReady;
    _status = fileReady
        ? VotRecordingStatus.completed
        : VotRecordingStatus.failed;
  }
}
