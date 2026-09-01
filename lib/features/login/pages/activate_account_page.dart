import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';
import '../services/auth_service.dart';
import '../utils/activation_link.dart';
import 'login_page.dart';

/// Form aktivasi akun dari deep link `sitara://activate?token=...`.
class ActivateAccountPage extends StatefulWidget {
  const ActivateAccountPage({
    super.key,
    required this.activationToken,
  });

  final String activationToken;

  @override
  State<ActivateAccountPage> createState() => _ActivateAccountPageState();
}

class _ActivateAccountPageState extends State<ActivateAccountPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  static const int _minPasswordLength = 8;
  static const int _maxPasswordLength = 72;
  static const int _minTokenLength = 32;
  static const int _maxTokenLength = 255;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor ?? AppColors.error,
        content: Text(message),
      ),
    );
  }

  Future<void> _activate() async {
    if (_isSubmitting) return;

    final String token = widget.activationToken.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmController.text;

    if (token.length < _minTokenLength || token.length > _maxTokenLength) {
      _showMessage("Link aktivasi tidak valid atau sudah kedaluwarsa.");
      return;
    }

    if (password.isEmpty || confirm.isEmpty) {
      _showMessage("Silakan lengkapi semua kolom kata sandi.");
      return;
    }

    if (password.length < _minPasswordLength) {
      _showMessage("Password baru minimal $_minPasswordLength karakter.");
      return;
    }

    if (password.length > _maxPasswordLength ||
        confirm.length > _maxPasswordLength) {
      _showMessage("Kata sandi terlalu panjang.");
      return;
    }

    if (password != confirm) {
      _showMessage("Kata sandi baru dan konfirmasi tidak sama.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      debugPrint(
        'POST /auth/activate token=${ActivationLink.maskToken(token)}',
      );

      await _authService.activateAccount(
        token: token,
        newPassword: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(
            notice:
                "Akun berhasil diaktifkan. Silakan login dengan username dan password baru Anda.",
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(ApiException.unexpectedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.loginGradientTop,
                AppColors.loginGradientBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Aktivasi Akun",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.healthPrimaryDark,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Buat password baru untuk mengaktifkan akun SITARA Anda.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.xlRadius,
                          border: Border.all(
                            color: AppColors.outlineVariantLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            SitaraTextField(
                              label: "Password Baru",
                              labelIcon: Icons.lock_outline,
                              hint: "••••••••",
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              readOnly: _isSubmitting,
                              suffixIcon: IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
                                      },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SitaraTextField(
                              label: "Konfirmasi Password Baru",
                              labelIcon: Icons.lock_outline,
                              hint: "••••••••",
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              readOnly: _isSubmitting,
                              suffixIcon: IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () =>
                                              _obscureConfirm = !_obscureConfirm,
                                        );
                                      },
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _activate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.healthPrimary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors
                                      .healthPrimary
                                      .withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.button,
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Aktifkan Akun",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
