import 'package:flutter/material.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/home_greeting_section.dart';
import '../widgets/home_progress_card.dart';
import '../widgets/home_medication_timer_card.dart';
import '../widgets/home_verification_section.dart';
import '../widgets/home_report_button.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../progress/pages/progress_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
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
                          children: const [

                            SitaraAppBar(),

                            SizedBox(height: 28),

                            HomeGreetingSection(),

                            SizedBox(height: 24),

                            HomeProgressCard(),

                            SizedBox(height: 24),

                            HomeMedicationTimerCard(),

                            SizedBox(height: 28),

                            HomeVerificationSection(),

                            SizedBox(height: 28),

                            HomeReportButton(),

                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SitaraBottomNavBar(
  currentIndex: 0,
  onTap: (index) {
    switch (index) {
      case 0:
        // Sudah di Home
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
        break;
    }
  },
),
          ],
        ),
      ),
    );
  }
}