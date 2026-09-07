import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

import '../../../shared/widgets/sitara_app_bar.dart';
import '../../../shared/widgets/sitara_bottom_nav_bar.dart';

import '../models/my_treatment.dart';
import '../models/patient_progress.dart';
import '../services/patient_progress_service.dart';
import '../services/treatment_service.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/progress_streak_card.dart';
import '../widgets/progress_timeline_card.dart';
import '../widgets/progress_activity_chart.dart';

import '../../home/pages/home_page.dart';
import '../../login/pages/login_page.dart';
import '../../login/services/auth_service.dart';
import '../../medicine/pages/medicine_page.dart';
import '../../profile/pages/profile_page.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    this.treatmentService,
    this.patientProgressService,
  });

  final TreatmentService? treatmentService;
  final PatientProgressService? patientProgressService;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  late final TreatmentService _treatmentService =
      widget.treatmentService ?? TreatmentService();

  late final PatientProgressService _patientProgressService =
      widget.patientProgressService ?? PatientProgressService();

  List<MyTreatment> _treatments = <MyTreatment>[];
  String? _treatmentError;

  PatientProgress? _patientProgress;
  String? _patientProgressError;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTreatments();
    _loadPatientProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    _loadTreatments();
    _loadPatientProgress();
  }

  Future<void> _refresh() async {
    await Future.wait(<Future<void>>[
      _loadTreatments(),
      _loadPatientProgress(),
    ]);
  }

  Future<void> _loadPatientProgress() async {
    if (mounted && !_isLoadingProgress) {
      setState(() {
        _isLoadingProgress = true;
        _patientProgressError = null;
      });
    }

    try {
      final PatientProgress progress =
          await _patientProgressService.getMyProgress();

      if (!mounted) return;

      setState(() {
        _patientProgress = progress;
        _patientProgressError = null;
        _isLoadingProgress = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      if (error.statusCode == 401) {
        await _handleExpiredSession();
        return;
      }

      setState(() {
        _patientProgress = null;
        _patientProgressError = error.message;
        _isLoadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _patientProgress = null;
        _patientProgressError = ApiException.unexpectedMessage;
        _isLoadingProgress = false;
      });
    }
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _treatmentError = null;
    });

    try {
      final List<MyTreatment> treatments =
          await _treatmentService.getMyTreatments();

      if (!mounted) return;

      setState(() {
        _treatments = treatments;
        _treatmentError = null;
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

  MyTreatment? get _currentTreatment {
    return MyTreatment.selectCurrent(_treatments);
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
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SitaraAppBar(),
                              const SizedBox(height: 28),
                              ProgressSummaryCard(
                                patientProgress: _patientProgress,
                                isLoading: _isLoadingProgress,
                                errorMessage: _patientProgressError,
                                onRetry: _loadPatientProgress,
                              ),
                              const SizedBox(height: 24),
                              ProgressStreakCard(
                                patientProgress: _patientProgress,
                                isLoading: _isLoadingProgress,
                                errorMessage: _patientProgressError,
                              ),
                              const SizedBox(height: 24),
                              ProgressTimelineCard(
                                treatment: _currentTreatment,
                                errorMessage: _treatmentError,
                              ),
                              const SizedBox(height: 24),
                              ProgressActivityChart(
                                treatment: _currentTreatment,
                                errorMessage: _treatmentError,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
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
