import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/notification_settings_header.dart';
import '../widgets/notification_master_switch.dart';
import '../widgets/notification_category_title.dart';
import '../widgets/notification_setting_tile.dart';
import '../widgets/notification_information_card.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool masterNotification = true;

  bool medicineReminder = true;
  bool weeklyReport = true;

  bool chatMessage = true;
  bool programUpdate = false;

  bool healthNews = false;

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
                          children: [
                            const NotificationSettingsHeader(),

                            const SizedBox(height: 28),

                            const Text(
                              "Pusat Notifikasi",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Kelola bagaimana Anda menerima pembaruan kesehatan dan pesan penting.",
                              style: TextStyle(
                                fontSize: 17,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 28),

                            NotificationMasterSwitch(
                              value: masterNotification,
                              onChanged: (value) {
                                setState(() {
                                  masterNotification = value;

                                  medicineReminder = value;
                                  weeklyReport = value;
                                  chatMessage = value;
                                  programUpdate = value;
                                  healthNews = value;
                                });
                              },
                            ),

                            const SizedBox(height: 30),

                            const NotificationCategoryTitle(
                              title: "PENGINGAT KLINIS",
                            ),

                            const SizedBox(height: 12),

                            NotificationSettingTile(
                              icon: Icons.medication_outlined,
                              title: "Pengingat Obat",
                              subtitle:
                                  "Notifikasi jadwal minum obat Anda",
                              enabled: medicineReminder,
                              onChanged: (value) {
                                setState(() {
                                  medicineReminder = value;
                                });
                              },
                            ),

                            NotificationSettingTile(
                              icon: Icons.summarize_outlined,
                              title: "Laporan Mingguan",
                              subtitle:
                                  "Ringkasan kemajuan kesehatan Anda",
                              enabled: weeklyReport,
                              onChanged: (value) {
                                setState(() {
                                  weeklyReport = value;
                                });
                              },
                            ),

                            const SizedBox(height: 28),

                            const NotificationCategoryTitle(
                              title: "KOMUNIKASI",
                            ),

                            const SizedBox(height: 12),

                            NotificationSettingTile(
                              icon: Icons.chat_bubble_outline,
                              title: "Pesan Chat",
                              subtitle:
                                  "Pesan dari tenaga kesehatan SITARA",
                              enabled: chatMessage,
                              onChanged: (value) {
                                setState(() {
                                  chatMessage = value;
                                });
                              },
                            ),

                            NotificationSettingTile(
                              icon: Icons.update,
                              title: "Update Program",
                              subtitle:
                                  "Informasi terbaru seputar program SITARA",
                              enabled: programUpdate,
                              onChanged: (value) {
                                setState(() {
                                  programUpdate = value;
                                });
                              },
                            ),

                            const SizedBox(height: 28),

                            const NotificationCategoryTitle(
                              title: "LAINNYA",
                            ),

                            const SizedBox(height: 12),

                            NotificationSettingTile(
                              icon: Icons.campaign_outlined,
                              title: "Berita Kesehatan",
                              subtitle:
                                  "Tips harian untuk gaya hidup sehat",
                              enabled: healthNews,
                              onChanged: (value) {
                                setState(() {
                                  healthNews = value;
                                });
                              },
                            ),

                            const SizedBox(height: 30),

                            const NotificationInformationCard(),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SitaraBottomNavBar(
              currentIndex: 3,
            ),
          ],
        ),
      ),
    );
  }
}