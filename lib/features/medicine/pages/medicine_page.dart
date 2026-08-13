  import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../models/my_medicine_schedule.dart';
import '../services/medicine_schedule_service.dart';
import '../widgets/medicine_header_section.dart';
import '../widgets/medicine_stock_card.dart';
import '../widgets/medicine_schedule_card.dart';
import '../widgets/medicine_list_card.dart';
import '../widgets/medicine_order_button.dart';
import '../widgets/medicine_note_card.dart';

import '../../home/pages/home_page.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../../progress/pages/progress_page.dart';
import '../../profile/pages/profile_page.dart';

class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});

  @override
  State<MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  final AuthService _authService = AuthService();
  final MedicineScheduleService _scheduleService = MedicineScheduleService();

  List<MyMedicineSchedule> _schedules = <MyMedicineSchedule>[];
  String? _scheduleError;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _scheduleError = null;
    });

    try {
      final List<MyMedicineSchedule> schedules =
          await _scheduleService.getMySchedules();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _scheduleError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _schedules = <MyMedicineSchedule>[];
        _scheduleError = ApiException.unexpectedMessage;
      });
    }
  }

  /// Kartu stok hanya punya satu angka, sedangkan pasien bisa memiliki lebih
  /// dari satu obat. Yang ditampilkan adalah obat dengan sisa proporsional
  /// paling sedikit, bukan penjumlahan antar obat yang satuannya tak diketahui.
  MyMedicineSchedule? get _lowestStockSchedule {
    return MyMedicineSchedule.selectLowestStock(_schedules);
  }

  MyMedicineSchedule? get _nextDrinkSchedule {
    return MyMedicineSchedule.selectNextDrink(_schedules);
  }

  Future<void> _handleExpiredSession() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
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

                            const SitaraAppBar(),

                            const SizedBox(height: 28),

                            const MedicineHeaderSection(),

                            const SizedBox(height: 24),

                            // MedicineWarningCard sengaja belum dirender.
                            // quantity_remaining kini sudah tersedia lewat
                            // GET /medicine-schedules/my, tetapi backend tidak
                            // menentukan ambang batas "stok hampir habis",
                            // sedangkan peringatan itu adalah klaim medis.
                            // Widget-nya tetap ada di
                            // widgets/medicine_warning_card.dart.
                            // TODO: Render kembali MedicineWarningCard bila
                            // backend menetapkan ambang batas peringatannya.
                            MedicineStockCard(
                              schedule: _lowestStockSchedule,
                              totalCount: _schedules.length,
                              errorMessage: _scheduleError,
                            ),

                            const SizedBox(height: 24),

                            MedicineScheduleCard(
                              schedule: _nextDrinkSchedule,
                              errorMessage: _scheduleError,
                            ),

                            const SizedBox(height: 24),

                            MedicineListCard(
                              schedules: _schedules,
                              errorMessage: _scheduleError,
                            ),

                            const SizedBox(height: 24),

                            const MedicineOrderButton(),

                            const SizedBox(height: 24),

                            const MedicineNoteCard(),

                            const SizedBox(height: 32),
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