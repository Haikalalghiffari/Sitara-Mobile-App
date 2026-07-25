import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';
import '../../../shared/widgets/sitara_top_bar.dart';

import '../widgets/report_notice_card.dart';
import '../widgets/report_title_section.dart';
import '../widgets/report_symptom_card.dart';
import '../widgets/report_notes_field.dart';
import '../widgets/report_submit_button.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController notesController = TextEditingController();

  final List<String> symptoms = [
    "Mual / Muntah",
    "Pusing",
    "Kulit Ruam / Gatal",
    "Nyeri Sendi",
    "Batuk Berdarah",
    "Lainnya",
  ];

  final List<IconData> icons = [
    Icons.sick_outlined,
    Icons.psychology_outlined,
    Icons.coronavirus_outlined,
    Icons.accessibility_new_outlined,
    Icons.priority_high,
    Icons.more_horiz,
  ];

  final Set<int> selectedSymptoms = {};

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

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

                            SitaraTopBar(
                              title: "Lapor Keluhan",
                              onBack: () {
                                Navigator.pop(context);
                              },
                            ),

                            const SizedBox(height: 28),

                            const ReportNoticeCard(),

                            const SizedBox(height: 28),

                            const ReportTitleSection(),

                            const SizedBox(height: 20),

                            ...List.generate(
                              symptoms.length,
                              (index) => ReportSymptomCard(
                                title: symptoms[index],
                                icon: icons[index],
                                isDanger: index == 4,
                                selected:
                                    selectedSymptoms.contains(index),
                                onTap: () {
                                  setState(() {
                                    if (selectedSymptoms.contains(index)) {
                                      selectedSymptoms.remove(index);
                                    } else {
                                      selectedSymptoms.add(index);
                                    }
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            ReportNotesField(
                              controller: notesController,
                            ),

                            const SizedBox(height: 32),

                            ReportSubmitButton(
                              onPressed: () {

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Laporan berhasil dikirim (UI Demo)",
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SitaraBottomNavBar(
              currentIndex: 1,
            ),
          ],
        ),
      ),
    );
  }
}