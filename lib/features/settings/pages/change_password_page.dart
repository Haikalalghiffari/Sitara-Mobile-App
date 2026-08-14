import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/sitara_text_field.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_save_button.dart';

/// Form ubah kata sandi. Tahap ini hanya UI, tanpa pemanggilan API.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(message),
      ),
    );
  }

  void _onSave() {
    final String current = _currentController.text;
    final String next = _newController.text;
    final String confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showMessage("Silakan lengkapi semua kolom kata sandi.");
      return;
    }

    if (next != confirm) {
      _showMessage("Kata sandi baru dan konfirmasi tidak sama.");
      return;
    }

    // TODO: Integrasikan dengan endpoint change password ketika backend tersedia.
    // Form divalidasi di perangkat, tetapi kata sandi tidak diubah dan tidak
    // ada permintaan ke server pada tahap ini.
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
                    "Perbarui kata sandi akun Anda. Perubahan belum dikirim ke server.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 28),

                  SitaraTextField(
                    label: "Kata Sandi Saat Ini",
                    labelIcon: Icons.lock_outline,
                    hint: "••••••••",
                    controller: _currentController,
                    obscureText: _obscureCurrent,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureCurrent = !_obscureCurrent);
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
                    label: "Kata Sandi Baru",
                    labelIcon: Icons.lock_outline,
                    hint: "••••••••",
                    controller: _newController,
                    obscureText: _obscureNew,
                    suffixIcon: IconButton(
                      onPressed: () {
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
                    label: "Konfirmasi Kata Sandi Baru",
                    labelIcon: Icons.lock_outline,
                    hint: "••••••••",
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
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
                    label: "Simpan Perubahan",
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
