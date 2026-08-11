import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/profile_header_section.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/logout_button.dart';

import '../../home/pages/home_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../medicine/pages/medicine_page.dart';

import '../../login/models/user_profile.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/patient_profile.dart';
import '../services/patient_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();

  UserProfile? _userProfile;
  PatientProfile? _patientProfile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserProfile user = await _authService.getProfile();
      final PatientProfile patient =
          await _patientService.getPatientProfile();

      if (!mounted) return;

      setState(() {
        _userProfile = user;
        _patientProfile = patient;
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

  /// Token ditolak backend, sesi tidak bisa dilanjutkan.
  ///
  /// Memakai [AuthService.logout] yang sudah ada agar tidak ada mekanisme
  /// pembersihan token baru.
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

  Widget _buildSummary() {
    if (_isLoading) {
      return const _ProfileCardShell(
        child: SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _ProfileCardError(
        message: _errorMessage!,
        onRetry: _loadProfile,
      );
    }

    final UserProfile? user = _userProfile;
    final PatientProfile? patient = _patientProfile;

    if (user != null && patient != null) {
      return ProfileSummaryCard(
        patient: patient,
        user: user,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: const SitaraAppBar(),

      bottomNavigationBar: SitaraBottomNavBar(
  currentIndex: 3,
  onTap: (index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProgressPage(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MedicinePage(),
          ),
        );
        break;

      case 3:
        // Sudah berada di halaman Profile
        break;
    }
  },
),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.screenHorizontal,
  vertical: AppSpacing.screenVertical,
),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Header
              ProfileHeaderSection(),

              SizedBox(height: 24),

              /// Profile Card
              _buildSummary(),

              SizedBox(height: 32),

              /// Menu
              ProfileMenuSection(),

              SizedBox(height: 34),

              /// Logout
              LogoutButton(),

              SizedBox(height: 24),

              // Harus mengikuti `version` pada pubspec.yaml.
              Center(
                child: Text(
                  "SITARA Health v1.0.0",
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wadah dengan tampilan yang sama seperti [ProfileSummaryCard], dipakai untuk
/// state loading dan error agar layout halaman tidak melompat.
class _ProfileCardShell extends StatelessWidget {
  const _ProfileCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: AppColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

class _ProfileCardError extends StatelessWidget {
  const _ProfileCardError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ProfileCardShell(
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
            label: const Text("Coba Lagi"),
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
