import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/notification_header.dart';
import '../widgets/notification_filter_tabs.dart';
import '../widgets/notification_section_title.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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

                            NotificationHeader(),

                            SizedBox(height: 24),

                            NotificationFilterTabs(),

                            SizedBox(height: 28),

                            NotificationSectionTitle(
                              title: "Terbaru",
                              actionText: "Tandai sudah dibaca",
                            ),

                            SizedBox(height: 16),

                            NotificationCard(
                              icon: Icons.medication,
                              iconBackground: AppColors.primary,
                              title: "Pengingat Minum Obat Malam",
                              subtitle:
                                  "Waktunya minum 1 tablet Rifampisin. Pastikan perut dalam keadaan kosong sebelum konsumsi.",
                              time: "Baru saja",
                              showActions: true,
                            ),

                            SizedBox(height: 18),

                            NotificationCard(
                              icon: Icons.chat_bubble,
                              iconBackground: Color(0xff66E5DB),
                              title: "Pesan dari Suster Amara",
                              subtitle:
                                  "\"Halo Rohan, bagaimana kabar hari ini? Apakah ada keluhan setelah minum obat?\"",
                              time: "10 mnt lalu",
                            ),

                            SizedBox(height: 30),

                            NotificationSectionTitle(
                              title: "Sebelumnya",
                            ),

                            SizedBox(height: 18),

                            NotificationCard(
                              icon: Icons.insights,
                              iconBackground: Color(0xffEEF3FF),
                              title: "Laporan Mingguan Siap",
                              subtitle:
                                  "Selamat! Kepatuhan Anda mencapai 98% minggu ini. Lihat detail kemajuan kesehatan Anda.",
                              time: "Kemarin\n09:00",
                            ),

                            SizedBox(height: 18),

                            NotificationCard(
                              icon: Icons.local_fire_department,
                              iconBackground: Color(0xffEEF3FF),
                              title: "Streak 15 Hari!",
                              subtitle:
                                  "Luar biasa! Anda telah konsisten minum obat tepat waktu selama 15 hari berturut-turut.",
                              time: "2 hari lalu",
                            ),

                            SizedBox(height: 40),

                            NotificationEmpty(),

                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SitaraBottomNavBar(
              currentIndex: 2,
            ),
          ],
        ),
      ),
    );
  }
}