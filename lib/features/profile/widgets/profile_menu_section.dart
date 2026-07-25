import 'package:flutter/material.dart';

import 'profile_menu_tile.dart';

import '../../medicine/pages/medicine_page.dart';
import '../pages/personal_information_page.dart';
import '../../notification/pages/notification_settings_page.dart';
import '../../help/pages/help_center_page.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileMenuTile(
          icon: Icons.person_outline_rounded,
          title: "Informasi Pribadi",
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
          icon: Icons.medication_outlined,
          title: "Logistik Obat",
          subtitle: "Lihat jadwal pengambilan obat",
          onTap: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const MedicinePage(),
    ),
  );
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