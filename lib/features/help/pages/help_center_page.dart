import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../widgets/help_header.dart';
import '../widgets/help_banner.dart';
import '../widgets/faq_section_header.dart';
import '../widgets/faq_tile.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

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

                            HelpHeader(),

                            SizedBox(height: 24),

                            HelpBanner(),

                            SizedBox(height: 32),

                            FAQSectionHeader(),

                            SizedBox(height: 18),

                            FAQTile(
                              question:
                                  "Bagaimana cara menggunakan AI VOT?",
                              answer:
                                  "Masuk ke menu Validasi Minum Obat, posisikan wajah dan obat sesuai petunjuk kamera, kemudian tekan tombol verifikasi. Sistem AI akan memastikan obat benar-benar diminum.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Apa yang harus saya lakukan jika lupa minum obat?",
                              answer:
                                  "Segera minum obat ketika Anda mengingatnya apabila masih sesuai dengan jadwal yang dianjurkan. Jika sudah mendekati jadwal berikutnya, ikuti petunjuk tenaga kesehatan dan jangan menggandakan dosis.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Bagaimana cara mendapatkan reward?",
                              answer:
                                  "Reward diberikan berdasarkan tingkat kepatuhan Anda dalam menjalankan terapi. Semakin konsisten melakukan verifikasi minum obat, semakin banyak poin yang diperoleh.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Mengapa saya harus melakukan verifikasi dengan kamera?",
                              answer:
                                  "Verifikasi kamera membantu memastikan bahwa obat benar-benar diminum sehingga tenaga kesehatan dapat memantau kepatuhan terapi secara lebih akurat.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Apakah data kesehatan saya aman?",
                              answer:
                                  "Ya. Data pasien disimpan secara aman dan hanya dapat diakses oleh pihak yang berwenang sesuai kebijakan privasi SITARA Health.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Bagaimana jika kamera gagal mengenali wajah saya?",
                              answer:
                                  "Pastikan pencahayaan cukup, wajah tidak tertutup masker atau benda lain, serta kamera berada pada posisi yang stabil. Anda dapat mencoba kembali beberapa saat kemudian.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Bagaimana jika saya kehabisan obat?",
                              answer:
                                  "Gunakan menu Pesan Ulang Obat atau hubungi fasilitas kesehatan yang menangani Anda untuk mendapatkan jadwal pengambilan obat berikutnya.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Apakah saya bisa mengubah jadwal pengingat obat?",
                              answer:
                                  "Ya. Jadwal pengingat dapat disesuaikan oleh tenaga kesehatan atau melalui pengaturan apabila fitur tersebut diaktifkan pada akun Anda.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Bagaimana cara menghubungi tenaga kesehatan?",
                              answer:
                                  "Masuk ke menu Pesan atau Chat pada aplikasi SITARA Health untuk mengirim pertanyaan langsung kepada petugas kesehatan yang menangani Anda.",
                            ),

                            SizedBox(height: 14),

                            FAQTile(
                              question:
                                  "Apa yang harus dilakukan jika aplikasi mengalami error?",
                              answer:
                                  "Pastikan koneksi internet stabil, gunakan aplikasi versi terbaru, kemudian coba buka kembali aplikasi. Jika masalah masih terjadi, hubungi tim dukungan SITARA Health.",
                            ),

                            SizedBox(height: 40),
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