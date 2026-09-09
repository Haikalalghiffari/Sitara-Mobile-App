import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/login/models/user_profile.dart';
import 'package:sitara/features/login/services/auth_service.dart';
import 'package:sitara/features/profile/models/patient_profile.dart';
import 'package:sitara/features/profile/pages/profile_page.dart';
import 'package:sitara/features/profile/services/patient_service.dart';
import 'package:sitara/features/profile/widgets/profile_summary_card.dart';
import 'package:sitara/features/progress/models/my_treatment.dart';
import 'package:sitara/features/progress/models/patient_progress.dart';
import 'package:sitara/features/progress/services/patient_progress_service.dart';
import 'package:sitara/features/progress/services/treatment_service.dart';

void main() {
  test('Profile memakai GET /medications/progress yang sama dengan Progress', () {
    expect(ApiEndpoints.medicationsProgress, '/medications/progress');
  });

  testWidgets('kepatuhan memakai adherence_percentage, bukan treatment', (
    WidgetTester tester,
  ) async {
    const TreatmentProgress treatmentProgress = TreatmentProgress(
      elapsedDays: 10,
      totalDays: 10,
      elapsedWeeks: 2,
      totalWeeks: 2,
      fraction: 1,
    );

    expect(treatmentProgress.assumedAdherence, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSummaryCard(
            patient: _patient(),
            user: _user(),
            progress: treatmentProgress,
            patientProgress: const PatientProgress(
              adherencePercentage: 88.9,
              successfulOccurrences: 8,
              failedOccurrences: 1,
              pendingReviewOccurrences: 0,
              finalDueOccurrences: 9,
              streakDays: 3,
            ),
          ),
        ),
      ),
    );

    expect(find.text('88.9%'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Kepatuhan'), findsOneWidget);
  });

  testWidgets('kepatuhan 100 dari progress, bukan rumus treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSummaryCard(
            patient: _patient(),
            user: _user(),
            progress: const TreatmentProgress(
              elapsedDays: 5,
              totalDays: 10,
              elapsedWeeks: 1,
              totalWeeks: 2,
              fraction: 0.5,
            ),
            patientProgress: const PatientProgress(
              adherencePercentage: 100,
              successfulOccurrences: 5,
              failedOccurrences: 0,
              pendingReviewOccurrences: 0,
              finalDueOccurrences: 5,
              streakDays: 5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('tanpa progress menampilkan em dash, bukan 100%', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSummaryCard(
            patient: _patient(),
            user: _user(),
            progress: const TreatmentProgress(
              elapsedDays: 10,
              totalDays: 10,
              elapsedWeeks: 2,
              totalWeeks: 2,
              fraction: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('ProfilePage memuat kepatuhan dari PatientProgressService', (
    WidgetTester tester,
  ) async {
    final _FakeProgressService progressService = _FakeProgressService(
      progress: const PatientProgress(
        adherencePercentage: 85,
        successfulOccurrences: 17,
        failedOccurrences: 3,
        pendingReviewOccurrences: 0,
        finalDueOccurrences: 20,
        streakDays: 4,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          authService: _FakeAuthService(),
          patientService: _FakePatientService(),
          treatmentService: _FakeTreatmentService(),
          patientProgressService: progressService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(progressService.calls, 1);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Kepatuhan'), findsOneWidget);
  });

  testWidgets('error progress tidak menghitung adherence sendiri', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          authService: _FakeAuthService(),
          patientService: _FakePatientService(),
          treatmentService: _FakeTreatmentService(),
          patientProgressService: _FakeProgressService(
            error: const ApiException('Server tidak dapat dihubungi.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Kepatuhan'), findsOneWidget);
  });
}

UserProfile _user() {
  return const UserProfile(
    id: 7,
    username: 'pasien',
    email: 'pasien@example.com',
    role: 'patient',
    isActive: true,
  );
}

PatientProfile _patient() {
  return const PatientProfile(
    id: 3,
    userId: 7,
    medicalRecordNumber: 'RM-1',
    fullName: 'Pasien Uji',
    nik: '123',
    birthDate: '1990-01-01',
    gender: 'male',
    phone: '0812',
    address: 'Alamat',
    occupation: 'Karyawan',
    pmoName: 'PMO',
    pmoPhone: '0813',
    clinicalNote: '',
    isActive: true,
    createdAt: '2026-01-01T00:00:00',
    updatedAt: '2026-01-01T00:00:00',
  );
}

class _FakeAuthService extends AuthService {
  @override
  Future<UserProfile> getProfile() async => _user();

  @override
  Future<void> logout() async {}
}

class _FakePatientService extends PatientService {
  @override
  Future<PatientProfile> getPatientProfile() async => _patient();
}

class _FakeTreatmentService extends TreatmentService {
  @override
  Future<List<MyTreatment>> getMyTreatments() async {
    return <MyTreatment>[
      const MyTreatment(
        id: 1,
        patientId: 3,
        therapyStartDate: '2026-01-01',
        therapyEndDate: '2026-12-31',
        phase: 'intensive',
        regimen: 'category_1',
        status: 'active',
        doctorName: 'Dokter',
      ),
    ];
  }
}

class _FakeProgressService extends PatientProgressService {
  _FakeProgressService({this.progress, this.error});

  final PatientProgress? progress;
  final ApiException? error;
  int calls = 0;

  @override
  Future<PatientProgress> getMyProgress() async {
    calls += 1;
    if (error != null) {
      throw error!;
    }
    return progress!;
  }
}
