  import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/medicine_header_section.dart';
import '../widgets/medicine_warning_card.dart';
import '../widgets/medicine_stock_card.dart';
import '../widgets/medicine_schedule_card.dart';
import '../widgets/medicine_list_card.dart';
import '../widgets/medicine_order_button.dart';
import '../widgets/medicine_note_card.dart';

import '../../home/pages/home_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../profile/pages/profile_page.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

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

                            MedicineHeaderSection(),

                            SizedBox(height: 24),

                            MedicineWarningCard(),

                            SizedBox(height: 24),

                            MedicineStockCard(),

                            SizedBox(height: 24),

                            MedicineScheduleCard(),

                            SizedBox(height: 24),

                            MedicineListCard(),

                            SizedBox(height: 24),

                            MedicineOrderButton(),

                            SizedBox(height: 24),

                            MedicineNoteCard(),

                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SitaraBottomNavBar(
  currentIndex: 2,
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
        // Sudah berada di halaman Obat
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