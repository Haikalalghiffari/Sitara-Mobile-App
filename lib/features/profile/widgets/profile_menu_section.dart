import 'package:flutter/material.dart';

import 'profile_menu_tile.dart';

import '../pages/personal_information_page.dart';
import '../../notification/pages/notification_settings_page.dart';
import '../../help/pages/help_center_page.dart';
import '../../settings/pages/settings_page.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    this.onReturnFromSettings,
  });

  /// Memakai pemuatan profil existing setelah Settings ditutup,
  /// termasuk setelah Ubah Username.
  final VoidCallback? onReturnFromSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileMenuTile(
          icon: Icons.person_outline_rounded,
          title: "Informasi Diri",
          subtitle: "Lihat dan ubah data pribadi Anda",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PersonalInformationPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        ProfileMenuTile(
          icon: Icons.settings_outlined,
          title: "Settings",
          subtitle: "Pengaturan akun dan profil",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
            onReturnFromSettings?.call();
          },
        ),

        const SizedBox(height: 14),

        ProfileMenuTile(
          icon: Icons.notifications_outlined,
          title: "Pengaturan Notifikasi",
          subtitle: "Atur pengingat dan notifikasi",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        ProfileMenuTile(
          icon: Icons.help_outline_rounded,
          title: "Bantuan",
          subtitle: "FAQ dan pusat bantuan",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpCenterPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
