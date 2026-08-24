import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/camera_status.dart';
import '../models/face_status.dart';
import '../models/face_verify_result.dart';
import '../models/verification_state.dart';
import '../pages/register_face_page.dart';
import '../services/face_service.dart';

import '../widgets/ai_vot_top_bar.dart';
import '../widgets/verification_action_button.dart';
import '../widgets/verification_camera_view.dart';
import '../widgets/verification_indicator_panel.dart';
import '../widgets/verification_info.dart';

/// Halaman verifikasi minum obat berbasis kamera (AI-VOT).
///
/// Halaman ini diakses dari Dashboard melalui tombol verifikasi minum obat,
/// bukan sebagai halaman utama.
class AiVotPage extends StatefulWidget {
  const AiVotPage({super.key});

  @override
  State<AiVotPage> createState() => _AiVotPageState();
}

class _AiVotPageState extends State<AiVotPage> with WidgetsBindingObserver {
  /// Hanya wajah yang diverifikasi di tahap ini. [VerificationState.success]
  /// sengaja tidak dipakai karena panel akan menandai Obat dan Keaslian
  /// selesai, padahal deteksi obat belum tersedia.
  VerificationState _state = VerificationState.ready;

  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;
  bool _awaitingRegistration = true;
  bool _isSubmitting = false;
  String? _statusError;
  String? _feedbackMessage;
  final FaceService _faceService = FaceService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _continueAfterRegistrationCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.inactive) {
      if (controller != null) {
        _releaseCamera();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        controller == null &&
        !_awaitingRegistration) {
      _initializeCamera();
    }
  }

  /// Guard pendaftaran wajah sebelum kamera VOT existing dijalankan.
  ///
  /// Sumber kebenaran adalah `GET /face/status`. Jika pasien membatalkan
  /// daftar wajah, halaman VOT ditutup agar kembali ke Home.
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

      if (!mounted) return;

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

  /// Melepas controller aktif tanpa menutup halaman.
  Future<void> _releaseCamera() async {
    final controller = _cameraController;
    _cameraController = null;

    if (mounted) {
      setState(() => _cameraStatus = CameraStatus.initializing);
    }

    await controller?.dispose();
  }

  Future<void> _initializeCamera() async {
    await _releaseCamera();

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _cameraStatus = CameraStatus.unavailable);
        return;
      }

      // Verifikasi minum obat memakai kamera depan bila tersedia.
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
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

  /// Satu kali tekan: ambil satu foto, kirim `POST /face/verify`, tunggu hasil.
  ///
  /// Tidak ada streaming frame. Bila gagal, pasien menekan Coba Lagi.
  Future<void> _startFaceVerification() async {
    if (_isSubmitting) return;

    if (!_cameraStatus.isReady) {
      setState(() {
        _feedbackMessage = _cameraStatus == CameraStatus.permissionDenied
            ? "Izin kamera diperlukan untuk verifikasi wajah."
            : "Kamera belum siap. Silakan coba lagi.";
      });
      return;
    }

    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      setState(() {
        _feedbackMessage = "Kamera belum siap. Silakan coba lagi.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
      _state = VerificationState.detectingFace;
    });

    String? capturedPath;

    try {
      final int medicineScheduleId =
          await _faceService.resolveMedicineScheduleId();

      if (!mounted) return;

      final CameraController? liveController = _cameraController;
      if (liveController == null ||
          !liveController.value.isInitialized ||
          liveController.value.isTakingPicture) {
        setState(() {
          _state = VerificationState.ready;
          _feedbackMessage = "Kamera belum siap. Silakan coba lagi.";
          _isSubmitting = false;
        });
        return;
      }

      final XFile photo = await liveController.takePicture();
      capturedPath = photo.path;

      if (!mounted) return;

      final FaceVerifyResult result = await _faceService.verifyFace(
        imagePath: capturedPath,
        medicineScheduleId: medicineScheduleId,
      );

      if (!mounted) return;

      if (result.verified) {
        setState(() {
          _state = VerificationState.faceVerified;
          _feedbackMessage = result.message.isNotEmpty
              ? result.message
              : "Wajah cocok dengan data pasien terdaftar.";
          _isSubmitting = false;
        });
        return;
      }

      setState(() {
        _state = VerificationState.failed;
        _feedbackMessage = _mismatchMessage(result);
        _isSubmitting = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      if (capturedPath == null) {
        setState(() {
          _state = VerificationState.ready;
          _feedbackMessage = error.message;
          _isSubmitting = false;
        });
        return;
      }

      _setFailed(error.message);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _state = VerificationState.ready;
        _feedbackMessage = "Foto tidak dapat diambil. Silakan coba lagi.";
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (capturedPath == null) {
        setState(() {
          _state = VerificationState.ready;
          _feedbackMessage = ApiException.unexpectedMessage;
          _isSubmitting = false;
        });
        return;
      }
      _setFailed(ApiException.unexpectedMessage);
    } finally {
      await _deleteTempFile(capturedPath);
    }
  }

  void _setFailed(String message) {
    setState(() {
      _state = VerificationState.failed;
      _feedbackMessage = message;
      _isSubmitting = false;
    });
  }

  String _mismatchMessage(FaceVerifyResult result) {
    final String base = result.message.isNotEmpty
        ? result.message
        : "Wajah tidak cocok dengan pasien terdaftar.";
    return "$base "
        "(kemiripan ${result.similarityScore.toStringAsFixed(2)}, "
        "ambang ${result.threshold.toStringAsFixed(2)}).";
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Berkas sementara; kegagalan hapus tidak mengubah alur.
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          title: const Text("Cara Verifikasi"),
          content: const Text(
            "1. Posisikan wajah dan tangan di dalam bingkai kamera.\n"
            "2. Perlihatkan obat pada area yang tersedia.\n"
            "3. Tekan Mulai Verifikasi, lalu minum obat seperti biasa.\n\n"
            "Pastikan ruangan cukup terang agar proses berjalan lancar.",
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
                            color: _state == VerificationState.failed
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  VerificationActionButton(
                    state: _state,
                    onStart: _cameraStatus.isReady && !_isSubmitting
                        ? _startFaceVerification
                        : null,
                    onRetry: _cameraStatus.isReady && !_isSubmitting
                        ? _startFaceVerification
                        : null,
                    onFinish: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  const VerificationInfo(),

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
