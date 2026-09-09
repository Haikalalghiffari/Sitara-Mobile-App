import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../ai_vot/models/face_status.dart';
import '../../ai_vot/pages/register_face_page.dart';
import '../../ai_vot/services/face_service.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_save_button.dart';

/// Status dan akses ke pendaftaran wajah yang sudah ada.
///
/// Tidak mengubah logic [RegisterFacePage] atau `POST /face/register`.
/// Status diambil dari `GET /face/status` lewat [FaceService.getStatus].
class FaceDataPage extends StatefulWidget {
  const FaceDataPage({
    super.key,
    this.faceService,
    this.authService,
    this.registerFaceBuilder,
  });

  final FaceService? faceService;
  final AuthService? authService;
  final WidgetBuilder? registerFaceBuilder;

  @override
  State<FaceDataPage> createState() => _FaceDataPageState();
}

class _FaceDataPageState extends State<FaceDataPage> {
  late final FaceService _faceService = widget.faceService ?? FaceService();
  late final AuthService _authService = widget.authService ?? AuthService();

  FaceStatus? _status;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final FaceStatus status = await _faceService.getStatus();
      if (!mounted) return;

      setState(() {
        _status = status;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = ApiException.unexpectedMessage;
        _isLoading = false;
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

  Future<void> _openExistingFaceRegister() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: widget.registerFaceBuilder ??
            (_) => const RegisterFacePage(),
      ),
    );

    if (!mounted) return;
    await _loadStatus();
  }

  Future<void> _onRegisterPressed() {
    return _openExistingFaceRegister();
  }

  Future<void> _onUpdatePressed() async {
    final bool confirmed = await _askUpdateConfirmation() ?? false;
    if (!confirmed || !mounted) return;
    await _openExistingFaceRegister();
  }

  Future<bool?> _askUpdateConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Perbarui Data Wajah?'),
          content: const Text(
            'Wajah yang terdaftar akan diperbarui melalui proses pendaftaran wajah.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Perbarui'),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsHeader(title: 'Data Wajah'),
                  const SizedBox(height: 28),
                  Text(
                    'Kelola data wajah untuk verifikasi.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 28),
                  _buildBody(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _FaceDataError(
        message: _errorMessage!,
        onRetry: _loadStatus,
      );
    }

    final bool isRegistered = _status?.isRegistered ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FaceStatusCard(isRegistered: isRegistered),
        const SizedBox(height: 32),
        if (isRegistered)
          SettingsSaveButton(
            label: 'Perbarui Data Wajah',
            onPressed: _onUpdatePressed,
          )
        else
          SettingsSaveButton(
            label: 'Daftarkan Wajah',
            onPressed: _onRegisterPressed,
          ),
      ],
    );
  }
}

class _FaceStatusCard extends StatelessWidget {
  const _FaceStatusCard({required this.isRegistered});

  final bool isRegistered;

  @override
  Widget build(BuildContext context) {
    final String label =
        isRegistered ? 'Wajah sudah terdaftar' : 'Belum terdaftar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isRegistered
                  ? AppColors.successContainer
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRegistered
                  ? Icons.check_rounded
                  : Icons.face_retouching_natural_outlined,
              color: isRegistered ? AppColors.success : AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isRegistered ? '✓ $label' : label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceDataError extends StatelessWidget {
  const _FaceDataError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 44,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Coba Lagi'),
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
    );
  }
}
