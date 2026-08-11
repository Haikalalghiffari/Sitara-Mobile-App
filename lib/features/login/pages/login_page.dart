import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../home/pages/home_page.dart';

import '../controllers/login_controller.dart';

import 'package:sitara/features/login/widgets/login_app_bar.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_form_card.dart';
import '../widgets/login_hero_section.dart';
import '../widgets/login_security_banner.dart';

/// Halaman Login SITARA Health
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LoginController _loginController = LoginController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showMessage("Username tidak boleh kosong");
      return;
    }

    if (password.isEmpty) {
      _showMessage("Password tidak boleh kosong");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _loginController.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (!profile.isActive) {
        await _loginController.logout();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage(
          "Akun Anda sedang tidak aktif. Hubungi petugas Puskesmas.",
          isError: true,
        );
        return;
      }

      if (!profile.isPatient) {
        await _loginController.logout();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showMessage(
          "Akun ini bukan akun pasien.",
          isError: true,
        );
        return;
      }

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(ApiException.unexpectedMessage, isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth > 600
                        ? AppSpacing.xxxl
                        : AppSpacing.screenHorizontal;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          const LoginAppBar(),

                          const SizedBox(
                            height: AppSpacing.xl,
                          ),

                          const LoginHeroSection(),

                          const SizedBox(
                            height: AppSpacing.xxxl,
                          ),

                          LoginFormCard(
                            obscurePassword: _obscurePassword,

                            onTogglePasswordVisibility: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },

                            usernameController: _usernameController,

                            passwordController:
                                _passwordController,

                            onLogin: _login,

                            isLoading: _isLoading,

                            onForgotPassword: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Fitur lupa password belum tersedia",
                                  ),
                                ),
                              );
                            },

                            onRegister: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Halaman pendaftaran belum tersedia",
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(
                            height: AppSpacing.xl,
                          ),

                          const LoginSecurityBanner(),

                          const LoginFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}