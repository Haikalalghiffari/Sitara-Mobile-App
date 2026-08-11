import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';

import '../widgets/personal_information_header.dart';
import '../widgets/personal_identity_card.dart';
import '../widgets/personal_contact_card.dart';
import '../widgets/personal_health_card.dart';
import '../widgets/privacy_note.dart';

import '../../login/models/user_profile.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../models/patient_profile.dart';
import '../services/patient_service.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
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
    _loadData();
  }

  Future<void> _loadData() async {
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

  Widget _buildContent() {
    if (_isLoading) {
      return const _StatusView(
        child: Padding(
          padding: EdgeInsets.only(top: 140),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _StatusView(
        child: _ErrorContent(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    final UserProfile? user = _userProfile;
    final PatientProfile? patient = _patientProfile;

    if (user == null || patient == null) {
      return const _StatusView(child: SizedBox.shrink());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        PersonalInformationHeader(patient: patient),

        const SizedBox(height: 32),

        PersonalIdentityCard(patient: patient),

        const SizedBox(height: 28),

        PersonalContactCard(
          patient: patient,
          user: user,
        ),

        const SizedBox(height: 28),

        PersonalHealthCard(patient: patient),

        const SizedBox(height: 32),

        const PrivacyNote(),

        const SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.screenVertical,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }
}

/// Pembungkus state loading dan error.
///
/// Tombol kembali tetap ditampilkan agar pengguna tidak terjebak di halaman
/// ini ketika data gagal dimuat.
class _StatusView extends StatelessWidget {
  const _StatusView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
              ),
            ),

            Expanded(
              child: Text(
                "Informasi Pribadi",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),

            const SizedBox(width: 48),
          ],
        ),

        child,
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardLarge,
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
      ),
    );
  }
}
