import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../medicine/models/my_medicine_schedule.dart';
import '../models/camera_status.dart';
import '../models/face_verification_result.dart';
import '../models/face_verification_state.dart';
import '../services/face_verification_api_service.dart';
import 'ai_vot_page.dart';
import '../widgets/ai_vot_top_bar.dart';
import '../widgets/register_face_camera_frame.dart';

/// Halaman Verifikasi Wajah Pasien sebelum sesi minum obat.
///
/// Memanggil backend POST /face/verify dengan menyertakan image dan
/// medicine_schedule_id.
///
/// PENTING (Phase 6 Boundary):
/// Halaman ini menampilkan hasil VERIFIED / FAILED dari server.
/// TIDAK secara otomatis memulai AI-VOT dan TIDAK memanggil video verification.
class MedicineVerificationPage extends StatefulWidget {
  const MedicineVerificationPage({
    super.key,
    required this.schedule,
  });

  final MyMedicineSchedule schedule;

  @override
  State<MedicineVerificationPage> createState() =>
      _MedicineVerificationPageState();
}

class _MedicineVerificationPageState extends State<MedicineVerificationPage>
    with WidgetsBindingObserver {
  final FaceVerificationApiService _verificationApiService =
      FaceVerificationApiService();

  FaceVerificationState _state = FaceVerificationState.initial;
  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;

  String? _capturedPath;
  FaceVerificationResult? _result;
  String? _errorMessage;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;

    if (state == AppLifecycleState.inactive) {
      if (controller != null &&
          (_state == FaceVerificationState.initial ||
              _state == FaceVerificationState.capturing)) {
        _releaseCamera();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        controller == null &&
        (_state == FaceVerificationState.initial ||
            _state == FaceVerificationState.capturing)) {
      _initializeCamera();
    }
  }

  Future<void> _releaseCamera() async {
    final CameraController? controller = _cameraController;
    _cameraController = null;

    if (mounted &&
        (_state == FaceVerificationState.initial ||
            _state == FaceVerificationState.capturing)) {
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
        if (_state == FaceVerificationState.initial) {
          _state = FaceVerificationState.capturing;
        }
      });
    } on CameraException catch (exception) {
      if (!mounted) return;
      setState(() {
        _cameraStatus = _mapCameraException(exception);
        if (_state == FaceVerificationState.capturing) {
          _state = FaceVerificationState.failed;
          _errorMessage = 'Kamera tidak dapat diakses.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraStatus = CameraStatus.unavailable;
        if (_state == FaceVerificationState.capturing) {
          _state = FaceVerificationState.failed;
          _errorMessage = 'Kamera tidak tersedia.';
        }
      });
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

  Future<void> _deleteCapturedFile() async {
    final String? path = _capturedPath;
    if (path == null) return;
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Mengambil foto dari kamera dan mengirim langsung ke backend POST /face/verify.
  Future<void> _captureAndVerify() async {
    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _state == FaceVerificationState.verifying) {
      return;
    }

    setState(() {
      _state = FaceVerificationState.verifying;
      _errorMessage = null;
    });

    try {
      final XFile photo = await controller.takePicture();
      await _releaseCamera();

      if (!mounted) return;

      setState(() {
        _capturedPath = photo.path;
      });

      // Panggil POST /face/verify dengan foto dan medicine_schedule_id
      final FaceVerificationResult result =
          await _verificationApiService.verifyFace(
        imagePath: photo.path,
        medicineScheduleId: widget.schedule.id,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _state = result.verified
            ? FaceVerificationState.verified
            : FaceVerificationState.failed;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _state = FaceVerificationState.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.unexpectedMessage;
        _state = FaceVerificationState.failed;
      });
    }
  }

  /// Mengulang proses verifikasi wajah dengan foto baru.
  Future<void> _retryVerification() async {
    await _deleteCapturedFile();
    if (!mounted) return;

    setState(() {
      _capturedPath = null;
      _result = null;
      _errorMessage = null;
      _state = FaceVerificationState.capturing;
    });

    await _initializeCamera();
  }

  void _onBack() {
    _releaseCamera();
    _deleteCapturedFile();
    Navigator.pop(context, _result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
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
                      title: 'Verifikasi Wajah Pasien',
                      onBack: _onBack,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildBodyContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    return Column(
      children: [
        // Ringkasan Jadwal Obat yang Akan Diverifikasi
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.schedule.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dosis:  | Jam: ',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Body berdasarkan State Machine Verifikasi
        switch (_state) {
          FaceVerificationState.initial ||
          FaceVerificationState.capturing =>
            _buildCameraView(),
          FaceVerificationState.verifying => _buildVerifyingView(),
          FaceVerificationState.verified => _buildVerifiedView(),
          FaceVerificationState.failed => _buildFailedView(),
        },
      ],
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        RegisterFaceCameraFrame(
          cameraStatus: _cameraStatus,
          controller: _cameraController,
          capturedImagePath: _capturedPath,
          onRetryCamera: _initializeCamera,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Posisikan wajah Anda di dalam lingkaran panduan sebelum mengambil foto.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight + 4,
          child: FilledButton(
            onPressed: _cameraStatus.isReady ? _captureAndVerify : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
            child: const Text(
              'Verifikasi Wajah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildVerifyingView() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60.0),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Memeriksa kecocokan wajah...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Backend SITARA sedang membandingkan embedding foto dengan data terdaftar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedView() {
    final FaceVerificationResult? res = _result;
    final double scorePercent = (res?.similarityScore ?? 0.0) * 100;
    final double thresholdPercent = (res?.threshold ?? 0.70) * 100;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '✓ Wajah Berhasil Diverifikasi',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          res?.message ?? 'Wajah cocok dengan data pasien terdaftar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Kotak Informasi Skor Kemiripan
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Skor Kemiripan:'),
                  Text(
                    '${scorePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ambang Batas (Threshold):'),
                  Text('${thresholdPercent.toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ID Verifikasi Server:'),
                  Text('#${res?.faceVerificationId ?? '-'}'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight + 4,
          child: FilledButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiVotPage(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
            child: const Text(
              'Lanjut ke AI-VOT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildFailedView() {
    final FaceVerificationResult? res = _result;
    final double scorePercent = (res?.similarityScore ?? 0.0) * 100;
    final double thresholdPercent = (res?.threshold ?? 0.70) * 100;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade200, width: 2),
          ),
          child: Icon(
            Icons.highlight_off_rounded,
            color: Colors.red.shade700,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '✕ Wajah Tidak Cocok',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage ??
              res?.message ??
              'Foto wajah tidak cocok dengan data pasien terdaftar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (res != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Skor Kemiripan:'),
                    Text(
                      '${scorePercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ambang Batas (Threshold):'),
                    Text('${thresholdPercent.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ID Audit Log Server:'),
                    Text('#${res.faceVerificationId}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight + 4,
          child: FilledButton(
            onPressed: _retryVerification,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: _onBack,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            side: const BorderSide(color: AppColors.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          child: const Text('Batal'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
