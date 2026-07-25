import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/progress_summary_card.dart';
import '../widgets/progress_streak_card.dart';
import '../widgets/progress_timeline_card.dart';
import '../widgets/progress_activity_chart.dart';

import '../../home/pages/home_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

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

                            ProgressSummaryCard(),

                            SizedBox(height: 24),

                            ProgressStreakCard(),

                            SizedBox(height: 24),

                            ProgressTimelineCard(),

                            SizedBox(height: 24),

                            ProgressActivityChart(),

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
  currentIndex: 1,
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
        // Sudah berada di halaman Progress
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