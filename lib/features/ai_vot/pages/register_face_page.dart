import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../models/camera_status.dart';
import '../models/face_register_result.dart';
import '../services/face_service.dart';
import '../widgets/ai_vot_top_bar.dart';
import '../widgets/register_face_camera_frame.dart';

enum _RegisterFaceStep { capture, preview, success }

/// Pendaftaran wajah ke backend `POST /face/register`.
///
/// Sukses hanya ditampilkan bila server mengembalikan `status: success`.
class RegisterFacePage extends StatefulWidget {
  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage>
    with WidgetsBindingObserver {
  final FaceService _faceService = FaceService();
  final AuthService _authService = AuthService();

  _RegisterFaceStep _step = _RegisterFaceStep.capture;
  CameraController? _cameraController;
  CameraStatus _cameraStatus = CameraStatus.initializing;
  String? _capturedPath;
  String? _successMessage;
  bool _isCapturing = false;
  bool _isSaving = false;
  bool _didPop = false;
  int _cameraEpoch = 0;
  Future<void>? _lifecycleGate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final CameraController? controller = _cameraController;
    _cameraController = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lifecycleGate = _handleBackground();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_handleForeground());
    }
  }

  Future<void> _handleBackground() async {
    if (_cameraController != null && _step == _RegisterFaceStep.capture) {
      await _releaseCamera();
    }
  }

  Future<void> _handleForeground() async {
    await _lifecycleGate;
    if (!mounted || _didPop) return;
    if (_cameraController == null && _step == _RegisterFaceStep.capture) {
      await _initializeCamera();
    }
  }

  Future<void> _releaseCamera({bool invalidateInFlight = true}) async {
    if (invalidateInFlight) {
      _cameraEpoch++;
    }
    final CameraController? controller = _cameraController;
    _cameraController = null;

    if (mounted && _step == _RegisterFaceStep.capture) {
      setState(() => _cameraStatus = CameraStatus.initializing);
    }

    await controller?.dispose();
  }

  Future<void> _initializeCamera() async {
    final CameraController? existing = _cameraController;
    if (existing != null &&
        existing.value.isInitialized &&
        _cameraStatus.isReady) {
      return;
    }

    final int epoch = ++_cameraEpoch;
    await _releaseCamera(invalidateInFlight: false);

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (epoch != _cameraEpoch) return;

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

      if (!mounted || epoch != _cameraEpoch) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraStatus = CameraStatus.ready;
      });
    } on CameraException catch (exception) {
      if (!mounted || epoch != _cameraEpoch) return;
      setState(
        () => _cameraStatus = cameraStatusFromExceptionCode(exception.code),
      );
    } catch (_) {
      if (!mounted || epoch != _cameraEpoch) return;
      setState(() => _cameraStatus = CameraStatus.unavailable);
    }
  }

  Future<void> _retryCamera() async {
    if (_cameraStatus.needsAppSettings) {
      await openAppSettings();
      return;
    }
    await _initializeCamera();
  }

  Future<void> _handleExpiredSession() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(backgroundColor: backgroundColor, content: Text(message)),
    );
  }

  Future<void> _deleteCapturedFile() async {
    final String? path = _capturedPath;
    if (path == null) return;
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Berkas sementara; kegagalan hapus tidak mengubah alur.
    }
  }

  Future<void> _capture() async {
    if (_isCapturing || !_cameraStatus.isReady) return;

    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showMessage("Kamera belum siap. Silakan coba lagi.");
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await controller.takePicture();
      if (!mounted) return;

      await _releaseCamera();

      setState(() {
        _capturedPath = photo.path;
        _step = _RegisterFaceStep.preview;
        _isCapturing = false;
      });
    } on CameraException {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showMessage("Foto tidak dapat diambil. Silakan coba lagi.");
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showMessage("Foto tidak dapat diambil. Silakan coba lagi.");
    }
  }

  Future<void> _retake() async {
    await _deleteCapturedFile();
    if (!mounted) return;

    setState(() {
      _capturedPath = null;
      _step = _RegisterFaceStep.capture;
    });

    await _initializeCamera();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final String? path = _capturedPath;
    if (path == null || path.isEmpty) {
      _showMessage("Foto wajah belum tersedia. Silakan ambil ulang.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final FaceRegisterResult result = await _faceService.registerFace(
        imagePath: path,
      );

      await _deleteCapturedFile();

      if (!mounted) return;

      setState(() {
        _capturedPath = null;
        _successMessage = result.message;
        _step = _RegisterFaceStep.success;
        _isSaving = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() => _isSaving = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(ApiException.unexpectedMessage);
    }
  }

  void _onBack() {
    if (_isSaving || _isCapturing) return;
    if (_step == _RegisterFaceStep.success) {
      _popOnce(true);
      return;
    }
    _popOnce(false);
  }

  void _continueToVerification() {
    _popOnce(true);
  }

  void _popOnce(bool result) {
    if (_didPop) return;
    _didPop = true;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
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
                    AiVotTopBar(title: "Daftar Wajah", onBack: _onBack),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _step == _RegisterFaceStep.success
                            ? _SuccessBody(
                                message:
                                    _successMessage ??
                                    "Wajah pasien berhasil didaftarkan.",
                                onContinue: _continueToVerification,
                              )
                            : _CaptureBody(
                                step: _step,
                                cameraStatus: _cameraStatus,
                                controller: _cameraController,
                                capturedPath: _capturedPath,
                                isCapturing: _isCapturing,
                                isSaving: _isSaving,
                                onRetryCamera: _retryCamera,
                                onCapture:
                                    _cameraStatus.isReady && !_isCapturing
                                    ? _capture
                                    : null,
                                onRetake: _retake,
                                onSave: _save,
                              ),
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
}

class _CaptureBody extends StatelessWidget {
  const _CaptureBody({
    required this.step,
    required this.cameraStatus,
    required this.isCapturing,
    required this.isSaving,
    required this.onRetryCamera,
    required this.onRetake,
    required this.onSave,
    this.controller,
    this.capturedPath,
    this.onCapture,
  });

  final _RegisterFaceStep step;
  final CameraStatus cameraStatus;
  final CameraController? controller;
  final String? capturedPath;
  final bool isCapturing;
  final bool isSaving;
  final VoidCallback onRetryCamera;
  final VoidCallback? onCapture;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bool isPreview = step == _RegisterFaceStep.preview;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.face_retouching_natural_outlined,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Daftarkan Wajah",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Daftarkan wajah Anda terlebih dahulu untuk proses verifikasi saat minum obat.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Wajah Anda akan digunakan untuk verifikasi identitas saat melakukan video observasi terapi.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        RegisterFaceCameraFrame(
          cameraStatus: cameraStatus,
          controller: controller,
          capturedImagePath: capturedPath,
          onRetryCamera: onRetryCamera,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isPreview
              ? "Pastikan wajah terlihat jelas sebelum menyimpan."
              : "Posisikan wajah Anda di dalam lingkaran",
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
              onPressed: isSaving ? null : onRetake,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: const Text(
                "Ambil Ulang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrimaryButton(
            label: "Simpan Wajah",
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ] else
          _PrimaryButton(
            label: "Daftarkan Wajah",
            isLoading: isCapturing,
            onPressed: onCapture,
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.message, required this.onContinue});

  final String message;
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
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _PrimaryButton(
          label: "Lanjut ke Video Verifikasi",
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
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
