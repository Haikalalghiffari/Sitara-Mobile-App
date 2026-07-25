import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
              ProfileSummaryCard(),

              SizedBox(height: 32),

              /// Menu
              ProfileMenuSection(),

              SizedBox(height: 34),

              /// Logout
              LogoutButton(),

              SizedBox(height: 24),

              Center(
                child: Text(
                  "SITARA Health v2.4.1",
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