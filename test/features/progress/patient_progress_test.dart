import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_client.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/progress/models/my_treatment.dart';
import 'package:sitara/features/progress/models/patient_progress.dart';
import 'package:sitara/features/progress/pages/progress_page.dart';
import 'package:sitara/features/progress/services/patient_progress_service.dart';
import 'package:sitara/features/progress/services/treatment_service.dart';
import 'package:sitara/features/progress/widgets/progress_streak_card.dart';
import 'package:sitara/features/progress/widgets/progress_summary_card.dart';
import 'package:sitara/features/progress/widgets/progress_timeline_card.dart';

/// Response contoh dari `GET /medications/progress`.
Map<String, dynamic> _progressJson({
  Object? adherence = 88.9,
  int successful = 8,
  int failed = 1,
  int pendingReview = 1,
  int finalDue = 9,
  int streak = 0,
}) {
  return <String, dynamic>{
    'adherence_percentage': adherence,
    'successful_occurrences': successful,
    'failed_occurrences': failed,
    'pending_review_occurrences': pendingReview,
    'final_due_occurrences': finalDue,
    'streak_days': streak,
  };
}

PatientProgress _progress({
  double? adherence = 88.9,
  int successful = 8,
  int failed = 1,
  int pendingReview = 1,
  int finalDue = 9,
  int streak = 0,
}) {
  return PatientProgress(
    adherencePercentage: adherence,
    successfulOccurrences: successful,
    failedOccurrences: failed,
    pendingReviewOccurrences: pendingReview,
    finalDueOccurrences: finalDue,
    streakDays: streak,
  );
}

Widget _summaryApp({
  PatientProgress? progress,
  bool isLoading = false,
  String? errorMessage,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProgressSummaryCard(
          patientProgress: progress,
          isLoading: isLoading,
          errorMessage: errorMessage,
        ),
      ),
    ),
  );
}

Widget _streakApp({
  PatientProgress? progress,
  bool isLoading = false,
  String? errorMessage,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProgressStreakCard(
          patientProgress: progress,
          isLoading: isLoading,
          errorMessage: errorMessage,
        ),
      ),
    ),
  );
}

/// Service palsu: tidak ada HTTP, mengikuti pola injeksi service pada test
/// notification yang sudah ada.
class _FakeProgressService extends PatientProgressService {
  _FakeProgressService({this.result, this.error})
      : super(apiClient: ApiClient(dio: Dio()));

  final PatientProgress? result;
  final Object? error;

  int calls = 0;

  @override
  Future<PatientProgress> getMyProgress() async {
    calls++;
    final Object? failure = error;
    if (failure != null) throw failure;
    return result!;
  }
}

class _EmptyTreatmentService extends TreatmentService {
  _EmptyTreatmentService() : super(apiClient: ApiClient(dio: Dio()));

  @override
  Future<List<MyTreatment>> getMyTreatments() async => <MyTreatment>[];
}

void main() {
  test('progress memakai GET /medications/progress', () {
    expect(ApiEndpoints.medicationsProgress, '/medications/progress');
    expect(
      ApiEndpoints.medicationsProgress,
      isNot(ApiEndpoints.medicationsToday),
    );
  });

  test('1. adherence 88.9 diparse dan dilabeli tanpa pembulatan', () {
    final PatientProgress progress =
        PatientProgress.fromJson(_progressJson());

    expect(progress.adherencePercentage, 88.9);
    expect(progress.adherenceLabel, '88.9%');
    expect(progress.hasAdherence, isTrue);
    expect(progress.adherenceFraction, closeTo(0.889, 0.0001));
    expect(progress.successfulOccurrences, 8);
    expect(progress.failedOccurrences, 1);
    expect(progress.pendingReviewOccurrences, 1);
    expect(progress.finalDueOccurrences, 9);
    expect(progress.streakDays, 0);
  });

  test('1b. integer dan desimal JSON keduanya terbaca', () {
    expect(
      PatientProgress.fromJson(_progressJson(adherence: 100)).adherenceLabel,
      '100%',
    );
    expect(
      PatientProgress.fromJson(_progressJson(adherence: '88.9'))
          .adherencePercentage,
      88.9,
    );
  });

  test('2. adherence null bukan 0 dan bukan 100', () {
    final PatientProgress progress = PatientProgress.fromJson(
      _progressJson(adherence: null),
    );

    expect(progress.adherencePercentage, isNull);
    expect(progress.hasAdherence, isFalse);
    expect(progress.adherenceLabel, isNull);
    expect(progress.adherenceFraction, isNull);
  });

  test('2b. field jumlah yang absen dianggap 0, parsing tidak gagal', () {
    final PatientProgress progress =
        PatientProgress.fromJson(<String, dynamic>{});

    expect(progress.adherencePercentage, isNull);
    expect(progress.successfulOccurrences, 0);
    expect(progress.failedOccurrences, 0);
    expect(progress.pendingReviewOccurrences, 0);
    expect(progress.finalDueOccurrences, 0);
    expect(progress.streakDays, 0);
  });

  testWidgets('1c. kartu kepatuhan menampilkan 88.9%', (tester) async {
    await tester.pumpWidget(_summaryApp(progress: _progress()));

    expect(find.text('88.9%'), findsOneWidget);
    expect(find.text('Kepatuhan'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('2c. adherence null tidak ditampilkan sebagai 100%', (
    tester,
  ) async {
    await tester.pumpWidget(
      _summaryApp(progress: _progress(adherence: null, finalDue: 0)),
    );

    expect(find.text('100%'), findsNothing);
    expect(find.text('—'), findsOneWidget);
    expect(
      find.textContaining(ProgressSummaryCard.noAdherenceMessage),
      findsOneWidget,
    );
  });

  testWidgets('3-6. rincian occurrence tampil apa adanya dari backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      _summaryApp(
        progress: _progress(
          successful: 8,
          failed: 2,
          pendingReview: 3,
          finalDue: 13,
        ),
      ),
    );

    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    expect(find.text('Menunggu pemeriksaan'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    expect(find.text('Sudah jatuh tempo'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('7. streak memakai streak_days backend', (tester) async {
    await tester.pumpWidget(_streakApp(progress: _progress(streak: 5)));

    expect(find.text('5 Hari'), findsOneWidget);
    expect(find.text('Belum tersedia'), findsNothing);
  });

  testWidgets('7b. streak_days 0 tampil sebagai 0 Hari', (tester) async {
    await tester.pumpWidget(_streakApp(progress: _progress(streak: 0)));

    expect(find.text('0 Hari'), findsOneWidget);
    expect(find.text(ProgressStreakCard.emptyStreakMessage), findsOneWidget);
  });

  testWidgets('8. error API tidak crash dan tidak menjadi 100%', (
    tester,
  ) async {
    await tester.pumpWidget(
      _summaryApp(errorMessage: ApiException.connectionFailedMessage),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(
      find.text(ApiException.connectionFailedMessage),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _streakApp(errorMessage: ApiException.connectionFailedMessage),
    );

    expect(find.text('Belum tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('9. loading state bukan error dan bukan 100%', (tester) async {
    await tester.pumpWidget(_summaryApp(isLoading: true));

    expect(find.text(ProgressSummaryCard.loadingMessage), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.text('Terverifikasi'), findsNothing);

    await tester.pumpWidget(_streakApp(isLoading: true));

    expect(find.text(ProgressStreakCard.loadingMessage), findsOneWidget);
  });

  testWidgets('10. durasi terapi tetap dari therapy dates, bukan kepatuhan', (
    tester,
  ) async {
    final DateTime today = DateTime.now();
    final DateTime start = today.subtract(const Duration(days: 9));
    final DateTime end = today.add(const Duration(days: 10));

    String iso(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

    final MyTreatment treatment = MyTreatment.fromJson(<String, dynamic>{
      'id': 1,
      'patient_id': 2,
      'therapy_start_date': iso(start),
      'therapy_end_date': iso(end),
      'phase': 'intensive',
      'regimen': 'category_1',
      'status': 'active',
      'doctor_name': 'dr. Sari',
    });

    final TreatmentProgress progress = treatment.progress!;
    expect(progress.elapsedDays, 10);
    expect(progress.totalDays, 20);
    expect(progress.percent, 50);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProgressTimelineCard(treatment: treatment),
          ),
        ),
      ),
    );

    expect(find.text('50% Selesai'), findsOneWidget);
    expect(find.text('Hari ke-10 dari 20'), findsOneWidget);
  });

  testWidgets('halaman Progress memuat GET /medications/progress sekali', (
    tester,
  ) async {
    final _FakeProgressService service = _FakeProgressService(
      result: _progress(adherence: 88.9, streak: 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProgressPage(
          treatmentService: _EmptyTreatmentService(),
          patientProgressService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(find.text('88.9%'), findsOneWidget);
    expect(find.text('3 Hari'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('halaman Progress menahan error tanpa menampilkan 100%', (
    tester,
  ) async {
    final _FakeProgressService service = _FakeProgressService(
      error: const ApiException('Jaringan terputus.'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProgressPage(
          treatmentService: _EmptyTreatmentService(),
          patientProgressService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsNothing);
    expect(find.text('Jaringan terputus.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
