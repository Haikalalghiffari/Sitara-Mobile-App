import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_save_button.dart';

/// Form ubah kata sandi. Mengirim `PUT /auth/change-password`.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  /// Batas yang sama dengan `ChangePasswordRequest` di backend.
  static const int _newPasswordMinLength = 8;
  static const int _passwordMaxLength = 72;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
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

  Future<void> _onSave() async {
    if (_isSubmitting) return;

    final String current = _currentController.text;
    final String next = _newController.text;
    final String confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showMessage("Silakan lengkapi semua kolom kata sandi.");
      return;
    }

    if (current.length > _passwordMaxLength ||
        next.length > _passwordMaxLength) {
      _showMessage("Kata sandi terlalu panjang.");
      return;
    }

    if (next.length < _newPasswordMinLength) {
      _showMessage("Password baru minimal $_newPasswordMinLength karakter.");
      return;
    }

    if (next != confirm) {
      _showMessage("Kata sandi baru dan konfirmasi tidak sama.");
      return;
    }

    if (next == current) {
      _showMessage(
        "Password baru tidak boleh sama dengan password lama.",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String message = await _authService.changePassword(
        currentPassword: current,
        newPassword: next,
      );

      if (!mounted) return;

      _currentController.clear();
      _newController.clear();
      _confirmController.clear();

      _showMessage(
        message,
        backgroundColor: AppColors.primary,
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage(ApiException.unexpectedMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                  const SettingsHeader(title: "Ubah Password"),

                  const SizedBox(height: 28),

                  Text(
                    "Masukkan kata sandi saat ini dan kata sandi baru Anda.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 28),

                  SitaraTextField(
                    label: "Password Saat Ini",
                    labelIcon: Icons.lock_outline,
                    hint: "••••••••",
                    controller: _currentController,
                    obscureText: _obscureCurrent,
                    readOnly: _isSubmitting,
                    suffixIcon: IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              );
                            },
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  SitaraTextField(
                    label: "Password Baru",
                    labelIcon: Icons.lock_outline,
                    hint: "••••••••",
                    controller: _newController,
                    obscureText: _obscureNew,
                    readOnly: _isSubmitting,
                    suffixIcon: IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() => _obscureNew = !_obscureNew);
                            },
                      icon: Icon(
                        _obscureNew
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
                                () => _obscureConfirm = !_obscureConfirm,
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

                  SettingsSaveButton(
                    label: "Ubah Password",
                    isLoading: _isSubmitting,
                    onPressed: _onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
