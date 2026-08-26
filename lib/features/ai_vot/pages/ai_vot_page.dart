import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/camera_status.dart';
import '../models/daily_medication.dart';
import '../models/face_status.dart';
import '../models/verification_state.dart';
import '../models/vot_face_verify_result.dart';
import '../models/vot_medicine_detect_result.dart';
import '../models/vot_start_response.dart';
import '../pages/register_face_page.dart';
import '../services/face_service.dart';
import '../services/local_drinking_service.dart';
import '../services/vot_service.dart';
import '../utils/drinking_sequence.dart';
import '../utils/today_medication_picker.dart';
import '../utils/vot_completion_guard.dart';
import '../utils/vot_flow.dart';

import '../widgets/ai_vot_top_bar.dart';
import '../widgets/verification_action_button.dart';
import '../widgets/verification_camera_view.dart';
import '../widgets/verification_indicator_panel.dart';
import '../widgets/verification_info.dart';

class AiVotPage extends StatefulWidget {
  const AiVotPage({super.key});

  @override
  State<AiVotPage> createState() => _AiVotPageState();
}

class _AiVotPageState extends State<AiVotPage> with WidgetsBindingObserver {
  VerificationState _state = VerificationState.ready;

  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;
  bool _awaitingRegistration = true;
  bool _isBusy = false;
  bool _streaming = false;
  String? _statusError;
  String? _feedbackMessage;
  bool _phaseError = false;

  DailyMedication? _selected;
  int? _dailyMedicationId;
  MedicineBoundingBox? _detectionBox;
  Size? _capturedImageSize;
  String? _detectionLabel;

  final FaceService _faceService = FaceService();
  final VotService _votService = VotService();
  final AuthService _authService = AuthService();
  final LocalDrinkingService _drinkingService = LocalDrinkingService();
  final DrinkingSequenceMachine _drinkingMachine = DrinkingSequenceMachine();
  final VotCompletionGuard _completionGuard = VotCompletionGuard();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _continueAfterRegistrationCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _drinkingService.dispose();
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;

    if (state == AppLifecycleState.inactive) {
      if (controller != null) {
        _releaseCamera();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        controller == null &&
        !_awaitingRegistration &&
        _selected != null) {
      _initializeCamera().then((_) => _syncSessionOnResume());
    }
  }

  Future<void> _continueAfterRegistrationCheck() async {
    setState(() {
      _awaitingRegistration = true;
      _statusError = null;
    });

    try {
      final FaceStatus status = await _faceService.getStatus();
      if (!mounted) return;

      if (!status.isRegistered) {
        final bool? completed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const RegisterFacePage(),
          ),
        );

        if (!mounted) return;

        if (completed != true) {
          Navigator.pop(context);
          return;
        }

        final FaceStatus refreshed = await _faceService.getStatus();
        if (!mounted) return;

        if (!refreshed.isRegistered) {
          setState(() {
            _statusError =
                "Pendaftaran wajah belum tercatat di server. Silakan coba lagi.";
          });
          return;
        }
      }

      await _loadTodayMedication();
      if (!mounted) return;

      if (_selected == null) {
        setState(() {
          _awaitingRegistration = false;
        });
        return;
      }

      setState(() {
        _awaitingRegistration = false;
      });
      await _initializeCamera();
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }
      setState(() {
        _statusError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusError = ApiException.unexpectedMessage;
      });
    }
  }

  Future<void> _loadTodayMedication() async {
    final List<DailyMedication> today = await _votService.listToday();
    if (!mounted) return;

    if (today.isEmpty) {
      setState(() {
        _selected = null;
        _statusError = "Belum ada jadwal obat untuk hari ini.";
      });
      return;
    }

    final DailyMedication? picked = TodayMedicationPicker.pick(today);
    if (picked == null) {
      setState(() {
        _selected = null;
        _statusError =
            "Tidak ada jadwal obat yang dapat diverifikasi hari ini.";
      });
      return;
    }

    setState(() {
      _selected = picked;
      _statusError = null;
      if (picked.isInProgress) {
        _dailyMedicationId = picked.dailyMedicationId;
      }
    });
  }

  Future<void> _syncSessionOnResume() async {
    final int? id = _dailyMedicationId;
    if (id == null) return;
    if (_completionGuard.inFlight) return;
    if (_state == VerificationState.completed) return;

    try {
      final DailyMedication session = await _votService.getSession(id);
      if (!mounted) return;

      if (VotFlow.isServerVerified(
        status: session.status,
        votStep: session.votStep,
      )) {
        _completionGuard.markSuccess();
        setState(() {
          _selected = session;
          _state = VerificationState.completed;
          _feedbackMessage = "Verifikasi minum obat berhasil.";
          _phaseError = false;
          _isBusy = false;
        });
        return;
      }

      if (_state == VerificationState.completing) {
        setState(() => _selected = session);
        return;
      }

      setState(() {
        _selected = session;
        _state = VotFlow.afterSession(votStep: session.votStep);
        _phaseError = false;
      });

      if (_state == VerificationState.drinking) {
        await _beginDrinking();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
      }
    } catch (_) {}
  }

  Future<void> _handleExpiredSession() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _releaseCamera() async {
    await _stopImageStream();
    final CameraController? controller = _cameraController;
    _cameraController = null;
    if (mounted) {
      setState(() => _cameraStatus = CameraStatus.initializing);
    }
    await controller?.dispose();
  }

  Future<void> _initializeCamera() async {
    await _releaseCamera();

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _cameraStatus = CameraStatus.unavailable);
        return;
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (CameraDescription camera) =>
            camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final CameraController controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraStatus = CameraStatus.ready;
      });
    } on CameraException catch (exception) {
      if (!mounted) return;
      setState(() => _cameraStatus = _mapCameraException(exception));
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraStatus = CameraStatus.unavailable);
    }
  }

  CameraStatus _mapCameraException(CameraException exception) {
    return switch (exception.code) {
      "CameraAccessDenied" ||
      "CameraAccessDeniedWithoutPrompt" ||
      "CameraAccessRestricted" =>
        CameraStatus.permissionDenied,
      _ => CameraStatus.unavailable,
    };
  }

  Future<void> _onStartPressed() async {
    final DailyMedication? selected = _selected;
    if (selected == null || _isBusy) return;

    if (!_cameraStatus.isReady) {
      setState(() {
        _feedbackMessage = _cameraStatus == CameraStatus.permissionDenied
            ? "Izin kamera diperlukan untuk verifikasi."
            : "Kamera belum siap. Silakan coba lagi.";
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = null;
      _state = VerificationState.starting;
    });

    try {
      final VotStartResponse started = await _votService.start(
        medicineScheduleId: selected.medicineScheduleId,
      );
      if (!mounted) return;

      _dailyMedicationId = started.dailyMedicationId;
      if (_dailyMedicationId == null || _dailyMedicationId! <= 0) {
        setState(() {
          _state = VerificationState.ready;
          _isBusy = false;
          _phaseError = true;
          _feedbackMessage =
              "Server tidak mengirim daily_medication_id. Sesi VOT tidak dapat dilanjutkan.";
        });
        return;
      }
      final VerificationState next =
          VotFlow.afterStart(votStep: started.votStep);
      if (next == VerificationState.completed) {
        _completionGuard.markSuccess();
      }

      setState(() {
        _state = next;
        _isBusy = false;
      });

      if (next == VerificationState.faceVerifying) {
        await _captureAndVerifyFace();
      } else if (next == VerificationState.drinking) {
        await _beginDrinking();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }
      setState(() {
        _state = VerificationState.ready;
        _feedbackMessage = error.message;
        _phaseError = true;
        _isBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.ready;
        _feedbackMessage = ApiException.unexpectedMessage;
        _isBusy = false;
      });
    }
  }

  Future<void> _captureAndVerifyFace() async {
    final int? dailyId = _dailyMedicationId;
    if (_isBusy) return;
    if (dailyId == null || dailyId <= 0) {
      setState(() {
        _state = VerificationState.faceVerifying;
        _phaseError = true;
        _feedbackMessage =
            "ID sesi VOT tidak tersedia. Tidak dapat memverifikasi wajah.";
      });
      return;
    }

    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      setState(() {
        _feedbackMessage = "Kamera belum siap. Silakan coba lagi.";
        _phaseError = true;
        _state = VerificationState.faceVerifying;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = null;
      _state = VerificationState.faceVerifying;
    });

    String? capturedPath;
    try {
      final XFile photo = await controller.takePicture();
      capturedPath = photo.path;
      if (!mounted) return;

      final VotFaceVerifyResult result = await _votService.verifyFace(
        dailyMedicationId: dailyId,
        imagePath: capturedPath,
      );
      if (!mounted) return;

      if (result.verified) {
        setState(() {
          _state = VerificationState.faceVerified;
          _feedbackMessage = result.message.isNotEmpty
              ? result.message
              : "Wajah cocok dengan data pasien terdaftar.";
          _isBusy = false;
          _phaseError = false;
        });
        if (!mounted) return;
        setState(() {
          _state = VerificationState.medicineDetecting;
          _feedbackMessage = "Letakkan obat di dalam kotak.";
        });
        return;
      }

      setState(() {
        _state = VerificationState.faceVerifying;
        _phaseError = true;
        _feedbackMessage = _faceMismatchMessage(result);
        _isBusy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }
      setState(() {
        _state = VerificationState.faceVerifying;
        _phaseError = true;
        _feedbackMessage = error.message;
        _isBusy = false;
      });
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.faceVerifying;
        _phaseError = true;
        _feedbackMessage = "Foto tidak dapat diambil. Silakan coba lagi.";
        _isBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.faceVerifying;
        _phaseError = true;
        _feedbackMessage = ApiException.unexpectedMessage;
        _isBusy = false;
      });
    } finally {
      await _deleteTempFile(capturedPath);
    }
  }

  Future<void> _captureAndDetectMedicine() async {
    final int? dailyId = _dailyMedicationId;
    if (_isBusy) return;
    if (dailyId == null || dailyId <= 0) {
      setState(() {
        _state = VerificationState.medicineDetecting;
        _phaseError = true;
        _feedbackMessage =
            "ID sesi VOT tidak tersedia. Tidak dapat mendeteksi obat.";
      });
      return;
    }

    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      setState(() {
        _feedbackMessage = "Kamera belum siap. Silakan coba lagi.";
        _phaseError = true;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = null;
      _detectionBox = null;
      _state = VerificationState.medicineDetecting;
    });

    String? capturedPath;
    try {
      final XFile photo = await controller.takePicture();
      capturedPath = photo.path;
      _capturedImageSize = await _readImageSize(capturedPath);
      if (!mounted) return;

      final VotMedicineDetectResult result = await _votService.detectMedicine(
        dailyMedicationId: dailyId,
        imagePath: capturedPath,
      );
      if (!mounted) return;

      if (result.medicineMatch) {
        setState(() {
          _state = VerificationState.medicineMatched;
          _detectionBox = result.boundingBox;
          _detectionLabel = result.detectedMedicine;
          _feedbackMessage = _medicineSuccessMessage(result);
          _phaseError = false;
          _isBusy = false;
        });
        if (!mounted) return;
        await _beginDrinking();
        return;
      }

      final String message = result.detectedMedicine == null
          ? "Obat belum terdeteksi. Letakkan obat di dalam kotak."
          : (result.message.isNotEmpty
              ? result.message
              : "Obat yang terdeteksi tidak sesuai dengan jadwal.");

      setState(() {
        _state = VerificationState.medicineDetecting;
        _detectionBox = result.boundingBox;
        _detectionLabel = result.detectedMedicine;
        _feedbackMessage = message;
        _phaseError = true;
        _isBusy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }
      setState(() {
        _state = VerificationState.medicineDetecting;
        _phaseError = true;
        _feedbackMessage = error.message;
        _isBusy = false;
      });
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.medicineDetecting;
        _phaseError = true;
        _feedbackMessage = "Foto tidak dapat diambil. Silakan coba lagi.";
        _isBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.medicineDetecting;
        _phaseError = true;
        _feedbackMessage = ApiException.unexpectedMessage;
        _isBusy = false;
      });
    } finally {
      await _deleteTempFile(capturedPath);
    }
  }

  Future<void> _beginDrinking() async {
    await _stopImageStream();
    setState(() {
      _state = VerificationState.drinking;
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = "Verifikasi visual proses minum.";
    });

    try {
      await _drinkingService.initialize();
      _drinkingMachine.reset();
      await _startImageStream();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phaseError = true;
        _isBusy = false;
        _feedbackMessage =
            "MediaPipe tidak dapat dijalankan. Periksa kamera lalu coba lagi.";
      });
    }
  }

  Future<void> _startImageStream() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_streaming) return;

    await controller.startImageStream(_onCameraImage);
    _streaming = true;
  }

  Future<void> _stopImageStream() async {
    final CameraController? controller = _cameraController;
    if (controller != null && _streaming) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
    _streaming = false;
  }

  void _onCameraImage(CameraImage image) {
    if (_state != VerificationState.drinking) return;
    final CameraController? controller = _cameraController;
    if (controller == null) return;

    final DrinkingObservation? observation = _drinkingService.observeFrame(
      image: image,
      sensorOrientation: controller.description.sensorOrientation,
      frontCamera:
          controller.description.lensDirection == CameraLensDirection.front,
      now: DateTime.now(),
    );
    if (observation == null) return;

    final DrinkingStage stage = _drinkingMachine.update(
      handVisible: observation.handVisible,
      faceVisible: observation.faceVisible,
      handMouthDistance: observation.handMouthDistance,
      now: DateTime.now(),
    );

    if (stage == DrinkingStage.completed) {
      _completeAfterDrinking();
      return;
    }

    if (!mounted) return;
    final String hint = switch (stage) {
      DrinkingStage.waiting => "Tunjukkan tangan yang memegang obat.",
      DrinkingStage.handWithMedicine => "Dekatkan obat ke mulut.",
      DrinkingStage.approachingMouth => "Mendekati mulut...",
      DrinkingStage.nearMouth => "Tahan sebentar dekat mulut.",
      DrinkingStage.withdrawing => "Jauhkan tangan dari mulut.",
      DrinkingStage.completed => "Memverifikasi proses minum...",
    };
    if (_feedbackMessage != hint) {
      setState(() => _feedbackMessage = hint);
    }
  }

  Future<void> _completeAfterDrinking() async {
    if (!_completionGuard.tryBegin()) return;

    await _stopImageStream();
    await _drinkingService.dispose();

    final Map<String, Object>? body =
        VotFlow.completeRequestBody(_dailyMedicationId);
    if (body == null) {
      _completionGuard.markFailure();
      if (!mounted) return;
      setState(() {
        _state = VerificationState.completing;
        _phaseError = true;
        _isBusy = false;
        _feedbackMessage =
            "ID sesi VOT tidak tersedia. Tidak dapat menyelesaikan verifikasi.";
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _state = VotFlow.afterLocalDrinkingCompleted();
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = "Memverifikasi proses minum...";
    });

    await _submitCompleteRequest();
  }

  Future<void> _retryComplete() async {
    if (!_completionGuard.tryBegin()) return;

    final Map<String, Object>? body =
        VotFlow.completeRequestBody(_dailyMedicationId);
    if (body == null) {
      _completionGuard.markFailure();
      if (!mounted) return;
      setState(() {
        _state = VerificationState.completing;
        _phaseError = true;
        _isBusy = false;
        _feedbackMessage =
            "ID sesi VOT tidak tersedia. Tidak dapat menyelesaikan verifikasi.";
      });
      return;
    }

    setState(() {
      _state = VerificationState.completing;
      _isBusy = true;
      _phaseError = false;
      _feedbackMessage = "Memverifikasi proses minum...";
    });

    await _submitCompleteRequest();
  }

  Future<void> _submitCompleteRequest() async {
    final int? dailyId = _dailyMedicationId;
    if (dailyId == null || dailyId <= 0) {
      _completionGuard.markFailure();
      if (!mounted) return;
      setState(() {
        _state = VerificationState.completing;
        _isBusy = false;
        _phaseError = true;
        _feedbackMessage =
            "ID sesi VOT tidak tersedia. Tidak dapat menyelesaikan verifikasi.";
      });
      return;
    }

    try {
      final result = await _votService.complete(dailyMedicationId: dailyId);
      if (!mounted) return;

      if (result.isFinalSuccess) {
        _completionGuard.markSuccess();
        setState(() {
          _state = VerificationState.completed;
          _isBusy = false;
          _phaseError = false;
          _feedbackMessage = result.message.isNotEmpty
              ? result.message
              : "Verifikasi minum obat berhasil.";
        });
        return;
      }

      _completionGuard.markFailure();
      setState(() {
        _state = VerificationState.completing;
        _isBusy = false;
        _phaseError = true;
        _feedbackMessage = result.message.isNotEmpty
            ? result.message
            : "Verifikasi minum belum disimpan. Silakan coba lagi.";
      });
    } on ApiException catch (error) {
      _completionGuard.markFailure();
      if (!mounted) return;
      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }
      setState(() {
        _state = VerificationState.completing;
        _isBusy = false;
        _phaseError = true;
        _feedbackMessage = error.message;
      });
    } catch (_) {
      _completionGuard.markFailure();
      if (!mounted) return;
      setState(() {
        _state = VerificationState.completing;
        _isBusy = false;
        _phaseError = true;
        _feedbackMessage = ApiException.unexpectedMessage;
      });
    }
  }

  String _faceMismatchMessage(VotFaceVerifyResult result) {
    final String base = result.message.isNotEmpty
        ? result.message
        : "Wajah tidak cocok dengan pasien terdaftar.";
    return "$base "
        "(kemiripan ${result.similarityScore.toStringAsFixed(2)}, "
        "ambang ${result.threshold.toStringAsFixed(2)}).";
  }

  String _medicineSuccessMessage(VotMedicineDetectResult result) {
    final String name = result.detectedMedicine ?? result.expectedMedicine;
    final String conf = (result.confidence * 100).toStringAsFixed(0);
    if (result.message.isNotEmpty) {
      return "${result.message} ($name, $conf%)";
    }
    return "Obat sesuai dengan jadwal. ($name, $conf%)";
  }

  Future<Size?> _readImageSize(String path) async {
    try {
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(await File(path).readAsBytes());
      final ui.ImageDescriptor descriptor =
          await ui.ImageDescriptor.encoded(buffer);
      final Size size = Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      buffer.dispose();
      descriptor.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          title: const Text("Cara Verifikasi"),
          content: const Text(
            "1. Tekan Mulai Verifikasi, lalu posisikan wajah di kamera.\n"
            "2. Letakkan obat di dalam kotak, lalu tekan Deteksi Obat.\n"
            "3. Minum obat seperti biasa di depan kamera.\n\n"
            "Setelah gerakan minum terdeteksi, hasil dikirim ke server.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Mengerti"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingRegistration) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: _statusError == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusError!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: _continueAfterRegistrationCheck,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text("Coba Lagi"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.button,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    if (_selected == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                AiVotTopBar(
                  title: "AI-VOT Verifikasi",
                  onBack: () => Navigator.pop(context),
                  onHelp: _showHelp,
                ),
                const Spacer(),
                Text(
                  _statusError ?? "Belum ada jadwal obat untuk hari ini.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _continueAfterRegistrationCheck,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text("Muat Ulang"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final bool canAct = _cameraStatus.isReady && !_isBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  AiVotTopBar(
                    title: "AI-VOT Verifikasi",
                    onBack: () => Navigator.pop(context),
                    onHelp: _showHelp,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: VerificationCameraView(
                      state: _state,
                      cameraStatus: _cameraStatus,
                      controller: _cameraController,
                      onRetryCamera: _initializeCamera,
                      detectionBox: _detectionBox,
                      capturedImageSize: _capturedImageSize,
                      detectionLabel: _detectionLabel,
                      isFrontCamera: _cameraController?.description
                              .lensDirection ==
                          CameraLensDirection.front,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  VerificationIndicatorPanel(state: _state),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _phaseError
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  VerificationActionButton(
                    state: _state,
                    isBusy: _isBusy,
                    hasPhaseError: _phaseError,
                    onStart: canAct ? _onStartPressed : null,
                    onRetryFace: canAct ? _captureAndVerifyFace : null,
                    onDetectMedicine:
                        canAct ? _captureAndDetectMedicine : null,
                    onRetryMedicine:
                        canAct ? _captureAndDetectMedicine : null,
                    onRetryDrinking: canAct ? _beginDrinking : null,
                    onRetryComplete: !_isBusy ? _retryComplete : null,
                    onFinish: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  VerificationInfo(medicineName: _selected?.medicineName),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
