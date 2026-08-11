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

import '../../home/pages/home_page.dart';
import '../../progress/pages/progress_page.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

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

  /// Keluhan "Lainnya" tidak menjelaskan apa pun tanpa catatan,
  /// jadi catatan menjadi wajib ketika opsi ini dipilih.
  int get _otherSymptomIndex => symptoms.indexOf("Lainnya");

  /// Dicari berdasarkan nama, bukan posisi, agar styling peringatan tetap
  /// menempel pada gejala yang benar bila urutan daftar berubah.
  int get _dangerSymptomIndex => symptoms.indexOf("Batuk Berdarah");

  void _submitReport() {
    final String notes = notesController.text.trim();
    final bool hasSymptom = selectedSymptoms.isNotEmpty;

    if (!hasSymptom && notes.isEmpty) {
      _showMessage(
        "Silakan lengkapi laporan keluhan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (!hasSymptom) {
      _showMessage(
        "Silakan lengkapi semua informasi keluhan.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    if (selectedSymptoms.contains(_otherSymptomIndex) && notes.isEmpty) {
      _showMessage(
        "Silakan isi detail keluhan terlebih dahulu.",
        backgroundColor: AppColors.error,
      );
      return;
    }

    // Form sudah lengkap, tetapi laporan TIDAK dikirim ke mana pun.
    //
    // POST /complaints memakai require_nakes, dan ComplaintCreate mewajibkan
    // treatment_id yang tidak dapat diperoleh pasien secara sah. Karena itu
    // isi form sengaja TIDAK direset: pasien masih perlu membacakan keluhannya
    // kepada petugas kesehatan.
    //
    // TODO: Kirim POST /complaints beserta reset form setelah backend
    // menyediakan endpoint keluhan yang dapat diakses role patient dan cara
    // sah memperoleh treatment_id miliknya. Saat itu isLoading pada
    // ReportSubmitButton baru dipakai selama request berlangsung.
    _showMessage(
      "Laporan belum dapat dikirim melalui aplikasi. Sampaikan keluhan ini kepada petugas kesehatan.",
    );
  }

  /// Dipertahankan untuk dipakai setelah POST /complaints tersedia bagi
  /// pasien, supaya form dibersihkan hanya ketika laporan benar-benar terkirim.
  // ignore: unused_element
  void _resetForm() {
    notesController.clear();

    setState(() {
      selectedSymptoms.clear();
    });
  }

  /// [backgroundColor] dibiarkan null untuk pesan informasi, sehingga tidak
  /// tampil sebagai keberhasilan maupun kegagalan validasi.
  void _showMessage(String message, {Color? backgroundColor}) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Halaman ini dibuka dari Home, cukup kembali agar tidak
        // ada HomePage ganda di navigation stack.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomePage(),
            ),
          );
        }
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
                                isDanger: index == _dangerSymptomIndex,
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
                              onPressed: _submitReport,
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

            SitaraBottomNavBar(
              currentIndex: 0,
              onTap: _onBottomNavTap,
            ),
          ],
        ),
      ),
    );
  }
}