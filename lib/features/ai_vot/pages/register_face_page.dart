import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../models/camera_status.dart';
import '../models/face_status.dart';
import '../services/face_api_service.dart';
import '../storage/face_registration_storage.dart';
import '../widgets/ai_vot_top_bar.dart';
import '../widgets/register_face_camera_frame.dart';

enum _RegisterFaceStep {
  checkingStatus,
  statusOverview,
  capture,
  preview,
  uploading,
  success,
}

/// Halaman Pendaftaran Wajah Pasien SITARA.
///
/// Berkomunikasi dengan backend SITARA (GET /face/status dan POST /face/register).
/// Database backend adalah source of truth utama.
class RegisterFacePage extends StatefulWidget {
  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage>
    with WidgetsBindingObserver {
  final FaceApiService _faceApiService = FaceApiService();
  final FaceRegistrationStorage _storage = FaceRegistrationStorage();

  _RegisterFaceStep _step = _RegisterFaceStep.checkingStatus;
  FaceStatusResponse? _faceStatus;
  String? _errorMessage;

  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;
  String? _capturedPath;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRegistrationStatus();
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
      if (controller != null && _step == _RegisterFaceStep.capture) {
        _releaseCamera();
      }
      return;
    }

    if (state == AppLifecycleState.resumed &&
        controller == null &&
        _step == _RegisterFaceStep.capture) {
      _initializeCamera();
    }
  }

  /// Mengecek status pendaftaran wajah langsung ke backend database (Source of Truth).
  Future<void> _checkRegistrationStatus() async {
    setState(() {
      _step = _RegisterFaceStep.checkingStatus;
      _errorMessage = null;
    });

    try {
      final FaceStatusResponse status = await _faceApiService.getFaceStatus();
      if (!mounted) return;

      setState(() {
        _faceStatus = status;
        _step = _RegisterFaceStep.statusOverview;
      });

      if (status.isRegistered) {
        await _storage.markRegistered();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _step = _RegisterFaceStep.statusOverview;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.unexpectedMessage;
        _step = _RegisterFaceStep.statusOverview;
      });
    }
  }

  Future<void> _startCameraRegistration() async {
    setState(() {
      _step = _RegisterFaceStep.capture;
      _capturedPath = null;
      _errorMessage = null;
    });
    await _initializeCamera();
  }

  Future<void> _releaseCamera() async {
    final CameraController? controller = _cameraController;
    _cameraController = null;

    if (mounted && _step == _RegisterFaceStep.capture) {
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
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        CameraStatus.permissionDenied,
      _ => CameraStatus.unavailable,
    };
  }

  void _showMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _capture() async {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await controller.takePicture();
      await _releaseCamera();

      if (!mounted) return;

      setState(() {
        _capturedPath = photo.path;
        _step = _RegisterFaceStep.preview;
        _isCapturing = false;
      });
    } on CameraException catch (exception) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showMessage(exception.message ?? 'Gagal mengambil foto.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showMessage('Gagal mengambil foto dari kamera.');
    }
  }

  Future<void> _retake() async {
    await _deleteCapturedFile();
    if (!mounted) return;
    await _startCameraRegistration();
  }

  Future<void> _uploadFace() async {
    final String? path = _capturedPath;
    if (path == null) return;

    setState(() {
      _step = _RegisterFaceStep.uploading;
      _errorMessage = null;
    });

    try {
      await _faceApiService.registerFace(path);
      await _storage.markRegistered();
      await _deleteCapturedFile();

      if (!mounted) return;

      // Refresh status dari backend (Source of Truth)
      final FaceStatusResponse refreshedStatus =
          await _faceApiService.getFaceStatus();

      if (!mounted) return;

      setState(() {
        _faceStatus = refreshedStatus;
        _step = _RegisterFaceStep.success;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _step = _RegisterFaceStep.preview;
      });
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.unexpectedMessage;
        _step = _RegisterFaceStep.preview;
      });
      _showMessage(ApiException.unexpectedMessage);
    }
  }

  void _onBack() {
    if (_step == _RegisterFaceStep.capture || _step == _RegisterFaceStep.preview) {
      _releaseCamera();
      _deleteCapturedFile();
      setState(() {
        _step = _RegisterFaceStep.statusOverview;
      });
      return;
    }
    Navigator.pop(context, _faceStatus?.isRegistered ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _RegisterFaceStep.statusOverview ||
          _step == _RegisterFaceStep.success ||
          _step == _RegisterFaceStep.checkingStatus,
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
                      title: 'Pendaftaran Wajah',
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
    switch (_step) {
      case _RegisterFaceStep.checkingStatus:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 80.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Memeriksa status pendaftaran wajah...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );

      case _RegisterFaceStep.statusOverview:
        return _StatusOverviewBody(
          status: _faceStatus,
          errorMessage: _errorMessage,
          onRefresh: _checkRegistrationStatus,
          onStartRegistration: _startCameraRegistration,
        );

      case _RegisterFaceStep.capture:
      case _RegisterFaceStep.preview:
        return _CaptureBody(
          step: _step,
          cameraStatus: _cameraStatus,
          controller: _cameraController,
          capturedPath: _capturedPath,
          isCapturing: _isCapturing,
          onRetryCamera: _initializeCamera,
          onCapture: _cameraStatus.isReady && !_isCapturing ? _capture : null,
          onRetake: _retake,
          onUpload: _uploadFace,
        );

      case _RegisterFaceStep.uploading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 80.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Mendaftarkan wajah ke server SITARA...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Harap tunggu sebentar, backend sedang mengekstrak vektor fitur wajah.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );

      case _RegisterFaceStep.success:
        return _SuccessBody(
          onContinue: () {
            Navigator.pop(context, true);
          },
        );
    }
  }
}

class _StatusOverviewBody extends StatelessWidget {
  const _StatusOverviewBody({
    required this.status,
    required this.errorMessage,
    required this.onRefresh,
    required this.onStartRegistration,
  });

  final FaceStatusResponse? status;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onStartRegistration;

  @override
  Widget build(BuildContext context) {
    final bool isRegistered = status?.isRegistered ?? false;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isRegistered
                ? AppColors.primaryContainer
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isRegistered ? AppColors.primary : AppColors.outlineVariant,
              width: 2,
            ),
          ),
          child: Icon(
            isRegistered
                ? Icons.check_circle_outline_rounded
                : Icons.face_retouching_natural_outlined,
            color: isRegistered ? AppColors.primary : AppColors.textHint,
            size: 44,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isRegistered
              ? '✓ Wajah Sudah Terdaftar'
              : 'Wajah Belum Terdaftar',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isRegistered ? AppColors.primary : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isRegistered
              ? 'Data wajah Anda sudah tersimpan di database SITARA dan aktif digunakan untuk verifikasi minum obat.'
              : 'Daftarkan foto wajah Anda untuk memverifikasi identitas pasien sebelum melakukan observasi minum obat.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: AppRadius.card,
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Petunjuk Pendaftaran Wajah:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _BulletPoint('Pastikan posisi wajah berada di dalam bingkai panduan.'),
              const _BulletPoint('Gunakan pencahayaan ruangan yang cukup terang.'),
              const _BulletPoint('Pastikan hanya ada SATU wajah di dalam foto.'),
              const _BulletPoint('Lepas kacamata hitam, masker, atau penutup wajah.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _PrimaryButton(
          label: isRegistered ? 'Daftarkan Ulang Wajah' : 'Daftarkan Wajah',
          onPressed: onStartRegistration,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            side: const BorderSide(color: AppColors.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          child: const Text('Cek Ulang Status Database'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBody extends StatelessWidget {
  const _CaptureBody({
    required this.step,
    required this.cameraStatus,
    required this.isCapturing,
    required this.onRetryCamera,
    required this.onRetake,
    required this.onUpload,
    this.controller,
    this.capturedPath,
    this.onCapture,
  });

  final _RegisterFaceStep step;
  final CameraStatus cameraStatus;
  final CameraController? controller;
  final String? capturedPath;
  final bool isCapturing;
  final VoidCallback onRetryCamera;
  final VoidCallback? onCapture;
  final VoidCallback onRetake;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final bool isPreview = step == _RegisterFaceStep.preview;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        RegisterFaceCameraFrame(
          cameraStatus: cameraStatus,
          controller: controller,
          capturedImagePath: capturedPath,
          onRetryCamera: onRetryCamera,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isPreview
              ? 'Pastikan wajah terlihat jelas sebelum mendaftarkan.'
              : 'Posisikan wajah Anda di dalam lingkaran panduan',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (isPreview) ...[
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight + 4,
            child: OutlinedButton(
              onPressed: onRetake,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: const Text(
                'Ambil Ulang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrimaryButton(
            label: 'Mendaftarkan Wajah',
            onPressed: onUpload,
          ),
        ] else
          _PrimaryButton(
            label: 'Daftarkan Wajah',
            isLoading: isCapturing,
            onPressed: onCapture,
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Wajah berhasil didaftarkan ke server SITARA.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Data vektor embedding wajah Anda telah tersimpan secara aman di database server SITARA dan siap digunakan untuk verifikasi minum obat.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _PrimaryButton(
          label: 'Lanjut',
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight + 4,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
