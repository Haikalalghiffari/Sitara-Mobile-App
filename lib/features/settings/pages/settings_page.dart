import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../ai_vot/pages/register_face_page.dart';
import '../../profile/widgets/profile_menu_tile.dart';
import '../../profile/pages/personal_information_page.dart';
import '../widgets/settings_header.dart';
import 'change_password_page.dart';

/// Pusat pengaturan akun dan keamanan pasien SITARA.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                  const SettingsHeader(title: 'Settings'),

                  const SizedBox(height: 28),

                  Text(
                    'SETTINGS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Kelola verifikasi wajah, kata sandi, dan data diri Anda.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 28),

                  ProfileMenuTile(
                    icon: Icons.face_retouching_natural_outlined,
                    title: 'Pendaftaran Wajah',
                    subtitle: 'Kelola status foto wajah verifikasi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterFacePage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  ProfileMenuTile(
                    icon: Icons.lock_outline,
                    title: 'Ubah Password',
                    subtitle: 'Perbarui kata sandi akun',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  ProfileMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Informasi Diri',
                    subtitle: 'Ubah informasi pribadi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInformationPage(),
                        ),
                      );
                    },
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
