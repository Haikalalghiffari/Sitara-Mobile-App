import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../home/pages/home_page.dart';

import '../controllers/login_controller.dart';

import '../widgets/login_app_bar.dart';
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
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final LoginController _loginController = LoginController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final nik = _nikController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NIK tidak boleh kosong"),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak boleh kosong"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = await _loginController.login(
      nik: nik,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NIK atau Password salah"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
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

                            nikController: _nikController,

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