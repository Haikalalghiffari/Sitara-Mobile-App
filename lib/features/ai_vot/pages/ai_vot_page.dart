import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/camera_status.dart';
import '../models/verification_state.dart';
import '../services/simulated_verification_service.dart';
import '../services/verification_service.dart';

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
  /// Diganti dengan implementasi berbasis model AI ketika sudah tersedia.
  final VerificationService _service = SimulatedVerificationService();

  StreamSubscription<VerificationState>? _subscription;
  VerificationState _state = VerificationState.ready;

  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _service.cancel();
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

    if (state == AppLifecycleState.resumed && controller == null) {
      _initializeCamera();
    }
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

  void _startVerification() {
    _subscription?.cancel();

    _subscription = _service.start().listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  void _resetVerification() {
    _subscription?.cancel();
    _service.cancel();
    setState(() => _state = VerificationState.ready);
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

                  const SizedBox(height: AppSpacing.lg),

                  VerificationActionButton(
                    state: _state,
                    onStart:
                        _cameraStatus.isReady ? _startVerification : null,
                    onRetry: _resetVerification,
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
