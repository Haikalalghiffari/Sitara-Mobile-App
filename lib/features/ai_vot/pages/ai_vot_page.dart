import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../login/services/auth_service.dart';
import '../../medicine/models/my_medicine_schedule.dart';
import '../models/camera_status.dart';
import '../models/face_verification_result.dart';
import '../models/verification_state.dart';
import '../models/video_verification_request.dart';
import '../models/video_verification_result.dart';
import '../services/simulated_verification_service.dart';
import '../services/verification_service.dart';
import '../services/video_verification_api_service.dart';
import '../storage/face_registration_storage.dart';
import '../widgets/ai_vot_top_bar.dart';
import '../widgets/verification_action_button.dart';
import '../widgets/verification_camera_view.dart';
import '../widgets/verification_indicator_panel.dart';
import '../widgets/verification_info.dart';
import 'medicine_verification_page.dart';
import 'register_face_page.dart';

/// Halaman utama alur verifikasi minum obat AI-VOT.
///
/// Halaman ini berperan sebagai container utama:
/// 1. Mengatur lifecycle kamera dan status perizinan per perangkat.
/// 2. Memulai service verifikasi (VerificationService) saat pengguna menekan tombol.
/// 3. Menghubungkan hasil Face Verification (ace_verification_id) ke Video Verification.
class AiVotPage extends StatefulWidget {
  const AiVotPage({
    super.key,
    this.verificationService,
    this.schedule,
    this.verificationResult,
  });

  final VerificationService? verificationService;
  final MyMedicineSchedule? schedule;
  final FaceVerificationResult? verificationResult;

  @override
  State<AiVotPage> createState() => _AiVotPageState();
}

class _AiVotPageState extends State<AiVotPage> with WidgetsBindingObserver {
  late final VerificationService _verificationService =
      widget.verificationService ?? SimulatedVerificationService();

  VerificationState _state = VerificationState.ready;
  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;
  bool _awaitingRegistration = true;
  final FaceRegistrationStorage _faceRegistrationStorage =
      FaceRegistrationStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkVerificationGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationService.cancel();
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

  /// SECURITY GATE: Menjamin Face Verification telah berhasil sebelum AI-VOT dimulai.
  ///
  /// Bila belum ada verificationResult yang verified == true untuk jadwal obat ini,
  /// halaman ini akan membuka MedicineVerificationPage terlebih dahulu.
  /// Jika verifikasi wajah batal atau gagal -> AI-VOT DITUTUP (STOP) dan kamera TIDAK diaktifkan.
  Future<void> _checkVerificationGate() async {
    final FaceVerificationResult? result = widget.verificationResult;
    final MyMedicineSchedule? schedule = widget.schedule;

    // Pengecekan Keamanan Sesi Verifikasi Wajah
    if (result == null || !result.verified || result.faceVerificationId <= 0) {
      if (!mounted) return;

      if (schedule != null) {
        final dynamic verifyResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineVerificationPage(schedule: schedule),
          ),
        );

        if (!mounted) return;

        if (verifyResult is! FaceVerificationResult || !verifyResult.verified) {
          // Gate Batal / Gagal -> KELUAR dan STOP. AI-VOT TIDAK BOLEH DIMULAI.
          Navigator.pop(context);
          return;
        }
      } else {
        // Tidak ada jadwal obat & belum terverifikasi -> KELUAR dan STOP.
        Navigator.pop(context);
        return;
      }
    }

    // Pengecekan pendaftaran wajah perangkat
    final bool registered = await _faceRegistrationStorage.isRegistered();
    if (!mounted) return;

    if (!registered) {
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
    }

    if (!mounted) return;

    setState(() {
      _awaitingRegistration = false;
    });

    await _initializeCamera();
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
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        CameraStatus.permissionDenied,
      _ => CameraStatus.unavailable,
    };
  }

  /// Mengirim record Video Verification ke backend yang meneruskan ace_verification_id.
  Future<VideoVerificationResult?> submitVideoVerification() async {
    final FaceVerificationResult? result = widget.verificationResult;
    final MyMedicineSchedule? schedule = widget.schedule;

    // Rule 3, 7, 10: Validation for Null/Failed Face Verification or Mismatched Schedule
    if (result == null || !result.verified || result.faceVerificationId <= 0) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifikasi wajah belum tersedia. Silakan lakukan verifikasi wajah terlebih dahulu.',
          ),
        ),
      );
      return null;
    }

    if (schedule == null || schedule.id <= 0) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal minum obat tidak valid.'),
        ),
      );
      return null;
    }

    final request = VideoVerificationRequest(
      medicineScheduleId: schedule.id,
      faceVerificationId: result.faceVerificationId,
      verificationDate: DateTime.now().toIso8601String().split('T')[0],
      videoPath: '/storage/videos/med__.mp4',
      fileName: 'med_.mp4',
      mimeType: 'video/mp4',
      fileSize: 1024000,
    );

    try {
      final token = await AuthService().getToken();
      if (token != null && token.isNotEmpty) {
        return await VideoVerificationApiService().createVideoVerification(
          request: request,
          token: token,
        );
      }
      return null;
    } catch (e) {
      if (!mounted) return null;
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim verifikasi video: '),
        ),
      );
      return null;
    }
  }

  void _showVerificationUnavailable() {
    submitVideoVerification();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Verifikasi minum obat belum dapat diproses melalui aplikasi. '
          'Perlihatkan proses minum obat kepada petugas kesehatan.',
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
          title: const Text('Cara Verifikasi'),
          content: const Text(
            '1. Posisikan wajah dan tangan di dalam bingkai kamera.
'
            '2. Perlihatkan obat pada area yang tersedia.
'
            '3. Tekan Mulai Verifikasi, lalu minum obat seperti biasa.

'
            'Pastikan ruangan cukup terang agar proses berjalan lancar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingRegistration) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
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
                    title: widget.schedule != null
                        ? 'AI-VOT: '
                        : 'AI-VOT Verifikasi',
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
                    onFinish: () async {
                      await submitVideoVerification();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
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
