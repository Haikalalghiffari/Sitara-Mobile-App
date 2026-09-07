import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/features/progress/models/my_treatment.dart';
import 'package:sitara/features/progress/models/patient_progress.dart';
import 'package:sitara/features/progress/pages/progress_page.dart';
import 'package:sitara/features/progress/services/patient_progress_service.dart';
import 'package:sitara/features/progress/services/treatment_service.dart';
import 'package:sitara/features/progress/widgets/progress_streak_card.dart';
import 'package:sitara/features/progress/widgets/progress_summary_card.dart';

PatientProgress _progress({
  double? adherence = 88.9,
  int successful = 8,
  int failed = 1,
  int pending = 2,
  int due = 11,
  int streak = 5,
}) {
  return PatientProgress(
    adherencePercentage: adherence,
    successfulOccurrences: successful,
    failedOccurrences: failed,
    pendingReviewOccurrences: pending,
    finalDueOccurrences: due,
    streakDays: streak,
  );
}

void main() {
  test('GET /medications/progress endpoint tidak dihitung di aplikasi', () {
    expect(ApiEndpoints.medicationsProgress, '/medications/progress');
  });

  test('1. backend response parsed apa adanya', () {
    final PatientProgress progress = PatientProgress.fromJson(
      <String, dynamic>{
        'adherence_percentage': 88.9,
        'successful_occurrences': 8,
        'failed_occurrences': 1,
        'pending_review_occurrences': 2,
        'final_due_occurrences': 11,
        'streak_days': 5,
      },
    );

    expect(progress.adherencePercentage, 88.9);
    expect(progress.successfulOccurrences, 8);
    expect(progress.failedOccurrences, 1);
    expect(progress.pendingReviewOccurrences, 2);
    expect(progress.finalDueOccurrences, 11);
    expect(progress.streakDays, 5);
    expect(progress.adherenceLabel, '88.9%');
  });

  testWidgets('2-7. kartu menampilkan angka backend', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ProgressSummaryCard(patientProgress: _progress()),
              ProgressStreakCard(patientProgress: _progress()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('88.9%'), findsOneWidget);
    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Menunggu pemeriksaan'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Sudah jatuh tempo'), findsOneWidget);
    expect(find.text('11'), findsWidgets);
    expect(find.text('5 Hari'), findsOneWidget);
  });

  test('adherence null bukan 100%', () {
    final PatientProgress progress = PatientProgress.fromJson(
      <String, dynamic>{
        'successful_occurrences': 0,
        'failed_occurrences': 0,
        'pending_review_occurrences': 0,
        'final_due_occurrences': 0,
        'streak_days': 0,
      },
    );
    expect(progress.adherencePercentage, isNull);
    expect(progress.hasAdherence, isFalse);
  });

  testWidgets('8. refresh memuat ulang GET /medications/progress', (
    WidgetTester tester,
  ) async {
    final _FakeProgressService progressService = _FakeProgressService();
    await tester.pumpWidget(
      MaterialApp(
        home: ProgressPage(
          treatmentService: _FakeTreatmentService(),
          patientProgressService: progressService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(progressService.calls, 1);

    await tester.fling(find.byType(Scrollable).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(progressService.calls, greaterThanOrEqualTo(2));
  });
}

class _FakeProgressService extends PatientProgressService {
  int calls = 0;

  @override
  Future<PatientProgress> getMyProgress() async {
    calls += 1;
    return PatientProgress(
      adherencePercentage: 80,
      successfulOccurrences: 8,
      failedOccurrences: 1,
      pendingReviewOccurrences: 0,
      finalDueOccurrences: 9,
      streakDays: 3,
    );
  }
}

class _FakeTreatmentService extends TreatmentService {
  @override
  Future<List<MyTreatment>> getMyTreatments() async {
    return const <MyTreatment>[];
  }
}
