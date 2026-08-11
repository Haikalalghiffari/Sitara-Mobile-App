import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../models/camera_status.dart';
import '../models/verification_state.dart';

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
  /// Selalu [VerificationState.ready] karena tidak ada pipeline verifikasi
  /// yang dijalankan.
  ///
  /// SimulatedVerificationService sengaja tidak dipakai lagi: alur itu selalu
  /// berakhir pada VerificationState.success setelah jeda waktu, sehingga
  /// pasien diberi tahu dosisnya "sudah terverifikasi" padahal tidak ada
  /// deteksi apa pun dan tidak ada data yang terkirim. Berkasnya tetap ada di
  /// services/simulated_verification_service.dart.
  ///
  // TODO: Jalankan pipeline verifikasi sebenarnya setelah dua hal tersedia.
  // Pertama, model AI on-device sesuai kontrak di ai_detection_service.dart.
  // Kedua, jalur pengiriman hasil ke backend: saat ini POST
  // /video-verifications hanya menerima application/json berisi
  // medicine_schedule_id, video_path, file_name, mime_type, dan file_size —
  // tidak ada endpoint multipart untuk mengunggah berkas videonya, dan
  // medicine_schedule_id tidak dapat diperoleh pasien secara sah.
  final VerificationState _state = VerificationState.ready;

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

  /// Kamera tetap berfungsi, tetapi hasilnya belum bisa diverifikasi maupun
  /// dikirim, sehingga pasien diberi keterangan apa adanya.
  void _showVerificationUnavailable() {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "Verifikasi minum obat belum dapat diproses melalui aplikasi. "
          "Perlihatkan proses minum obat kepada petugas kesehatan.",
        ),
      ),
    );
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
                    onStart: _cameraStatus.isReady
                        ? _showVerificationUnavailable
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
