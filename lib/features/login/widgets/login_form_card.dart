import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';

/// Kartu form login: username, password, tombol masuk & daftar.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    this.usernameController,
    this.passwordController,
    this.onLogin,
    this.onRegister,
    this.onForgotPassword,
    this.isLoading = false,
  });

  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final TextEditingController? usernameController;
  final TextEditingController? passwordController;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onForgotPassword;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.outlineVariantLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SitaraTextField(
            label: 'Username',
            labelIcon: Icons.person_outline,
            hint: 'Masukkan username Anda',
            controller: usernameController,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: AppSpacing.xl),
          SitaraTextField(
            label: 'Kata Sandi',
            labelIcon: Icons.lock_outline,
            hint: '••••••••',
            controller: passwordController,
            obscureText: obscurePassword,
            labelTrailing: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.healthPrimary,
              ),
              child: Text(
                'Lupa Password?',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.healthPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onTogglePasswordVisibility,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
  height: 52,
  child: ElevatedButton(
    onPressed: isLoading ? null : onLogin,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.healthPrimary,
      foregroundColor: Colors.white,
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
        : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Masuk",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
  ),
), 
        ],
      ),
    );
  }
}
