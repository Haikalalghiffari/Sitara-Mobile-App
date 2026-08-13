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

import '../../../core/network/api_exception.dart';

import '../../login/models/user_profile.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';

import '../../profile/models/patient_profile.dart';
import '../../profile/services/patient_service.dart';

import '../../progress/models/my_treatment.dart';
import '../../progress/services/treatment_service.dart';

import '../../medicine/models/my_medicine_schedule.dart';
import '../../medicine/services/medicine_schedule_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();
  final TreatmentService _treatmentService = TreatmentService();
  final MedicineScheduleService _medicineScheduleService =
      MedicineScheduleService();

  UserProfile? _userProfile;
  PatientProfile? _patientProfile;
  String? _errorMessage;

  List<MyTreatment> _treatments = <MyTreatment>[];
  String? _treatmentError;

  List<MyMedicineSchedule> _medicineSchedules = <MyMedicineSchedule>[];
  String? _medicineScheduleError;

  @override
  void initState() {
    super.initState();
    // Dipanggil sekali di sini, bukan di build(), agar tidak ada request
    // berulang setiap kali widget di-rebuild.
    _loadProfile();
    _loadTreatments();
    _loadMedicineSchedules();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final UserProfile user = await _authService.getProfile();
      final PatientProfile patient =
          await _patientService.getPatientProfile();

      if (!mounted) return;

      setState(() {
        _userProfile = user;
        _patientProfile = patient;
        _reconcileTreatments();
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = ApiException.unexpectedMessage;
      });
    }
  }

  Future<void> _loadTreatments() async {
    try {
      final List<MyTreatment> treatments =
          await _treatmentService.getMyTreatments();

      if (!mounted) return;

      setState(() {
        _treatments = treatments;
        _treatmentError = null;
        _reconcileTreatments();
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _treatments = <MyTreatment>[];
        _treatmentError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _treatments = <MyTreatment>[];
        _treatmentError = ApiException.unexpectedMessage;
      });
    }
  }

  /// Memuat `GET /medicine-schedules/my` memakai service yang sama dengan
  /// MedicinePage, sehingga tidak ada endpoint atau service tambahan.
  ///
  /// Backend sudah menyaring berdasarkan pemegang token, dan responsnya tidak
  /// memuat `patient_id`, jadi tidak ada penyaringan ulang di sisi aplikasi.
  Future<void> _loadMedicineSchedules() async {
    try {
      final List<MyMedicineSchedule> schedules =
          await _medicineScheduleService.getMySchedules();

      if (!mounted) return;

      setState(() {
        _medicineSchedules = schedules;
        _medicineScheduleError = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _medicineSchedules = <MyMedicineSchedule>[];
        _medicineScheduleError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _medicineSchedules = <MyMedicineSchedule>[];
        _medicineScheduleError = ApiException.unexpectedMessage;
      });
    }
  }

  /// Backend `GET /treatments/my` seharusnya hanya mengirim pengobatan milik
  /// pemegang token. Bila `patient_id` tidak cocok dengan profil yang sedang
  /// login, data tidak ditampilkan.
  void _reconcileTreatments() {
    final int? patientId = _patientProfile?.id;
    if (patientId == null) return;

    if (_treatments.any((MyTreatment item) => item.patientId != patientId)) {
      _treatments = <MyTreatment>[];
      _treatmentError =
          'Data pengobatan tidak dapat ditampilkan karena server '
          'mengirim data milik pasien lain.';
    }
  }

  MyTreatment? get _currentTreatment {
    return MyTreatment.selectCurrent(_treatments);
  }

  MyMedicineSchedule? get _nextDrinkSchedule {
    return MyMedicineSchedule.selectNextDrink(_medicineSchedules);
  }

  /// Memakai [AuthService.logout] yang sudah ada agar tidak ada mekanisme
  /// pembersihan token baru.
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

                            HomeGreetingSection(
                              patient: _patientProfile,
                              user: _userProfile,
                              errorMessage: _errorMessage,
                              onRetry: () {
                                _loadProfile();
                                _loadTreatments();
                                _loadMedicineSchedules();
                              },
                            ),

                            const SizedBox(height: 24),

                            HomeProgressCard(
                              treatment: _currentTreatment,
                              errorMessage: _treatmentError,
                            ),

                            const SizedBox(height: 24),

                            HomeMedicationTimerCard(
                              schedule: _nextDrinkSchedule,
                              errorMessage: _medicineScheduleError,
                            ),

                            const SizedBox(height: 28),

                            const HomeVerificationSection(),

                            const SizedBox(height: 28),

                            const HomeReportButton(),

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