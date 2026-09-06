import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_client.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/medicine/models/control_schedule.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';
import 'package:sitara/features/medicine/models/refill.dart';
import 'package:sitara/features/medicine/pages/medicine_page.dart';
import 'package:sitara/features/medicine/pages/medicine_refill_page.dart';
import 'package:sitara/features/medicine/services/control_schedule_service.dart';
import 'package:sitara/features/medicine/services/medicine_schedule_service.dart';
import 'package:sitara/features/medicine/services/refill_service.dart';
import 'package:sitara/features/medicine/utils/refill_form_validation.dart';
import 'package:sitara/features/medicine/utils/refill_medicine_options.dart';
import 'package:sitara/features/medicine/widgets/refill_medicine_picker.dart';
import 'package:sitara/features/medicine/widgets/refill_summary_section.dart';
import 'package:sitara/features/progress/models/my_treatment.dart';
import 'package:sitara/features/progress/services/treatment_service.dart';

MyMedicineSchedule _schedule({
  int id = 1,
  int treatmentId = 7,
  required int medicineId,
  required String name,
  String dosage = '1 tablet',
  String drinkTime = '08:00:00',
}) {
  return MyMedicineSchedule(
    id: id,
    treatmentId: treatmentId,
    medicineId: medicineId,
    medicineName: name,
    dosage: dosage,
    quantityInitial: 30,
    quantityRemaining: 12,
    drinkTime: drinkTime,
  );
}

MyTreatment _treatment({int id = 7}) {
  return MyTreatment.fromJson(<String, dynamic>{
    'id': id,
    'patient_id': 2,
    'start_date': '2026-08-01',
    'end_date': '2026-12-01',
    'status': 'active',
  });
}

/// Service palsu tanpa HTTP, mengikuti pola injeksi service pada test Progress.
class _FakeScheduleService extends MedicineScheduleService {
  _FakeScheduleService({this.schedules, this.error})
      : super(apiClient: ApiClient(dio: Dio()));

  final List<MyMedicineSchedule>? schedules;
  final Object? error;
  int calls = 0;

  @override
  Future<List<MyMedicineSchedule>> getMySchedules() async {
    calls++;
    final Object? failure = error;
    if (failure != null) throw failure;
    return schedules ?? <MyMedicineSchedule>[];
  }
}

class _FakeTreatmentService extends TreatmentService {
  _FakeTreatmentService() : super(apiClient: ApiClient(dio: Dio()));

  @override
  Future<List<MyTreatment>> getMyTreatments() async =>
      <MyTreatment>[_treatment()];
}

class _FakeControlScheduleService extends ControlScheduleService {
  _FakeControlScheduleService() : super(apiClient: ApiClient(dio: Dio()));

  @override
  Future<List<ControlSchedule>> getMySchedules() async =>
      <ControlSchedule>[];
}

class _RecordingRefillService extends RefillService {
  _RecordingRefillService() : super(apiClient: ApiClient(dio: Dio()));

  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  @override
  Future<List<Refill>> getMyRefills() async => <Refill>[];

  @override
  Future<Refill> createRefill({
    required int treatmentId,
    required int medicineId,
    required int quantity,
    required String reason,
    String? description,
  }) async {
    requests.add(Refill.createRequestBody(
      treatmentId: treatmentId,
      medicineId: medicineId,
      quantity: quantity,
      reason: reason,
      description: description,
    ));

    return Refill.fromJson(<String, dynamic>{
      'id': 31,
      'treatment_id': treatmentId,
      'medicine_id': medicineId,
      'quantity': quantity,
      'reason': reason,
      'status': 'pending',
      'is_active': true,
      'created_at': '2026-09-06T05:00:00',
      'updated_at': '2026-09-06T05:00:00',
    });
  }
}

/// Form pesan ulang lebih tinggi dari 600 px bawaan test, sehingga tombol dan
/// centang berada di luar viewport. Layar test diperbesar agar interaksinya
/// benar-benar mengenai widget, bukan lolos karena berada di luar layar.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _refillPage({
  required List<MyMedicineSchedule> schedules,
  RefillService? refillService,
  Object? scheduleError,
}) {
  return MaterialApp(
    home: MedicineRefillPage(
      treatmentService: _FakeTreatmentService(),
      scheduleService: _FakeScheduleService(
        schedules: schedules,
        error: scheduleError,
      ),
      refillService: refillService ?? _RecordingRefillService(),
    ),
  );
}

void main() {
  group('Sumber dan deduplikasi pilihan obat', () {
    test('4 & 5: pilihan hanya dari jadwal pasien pada pengobatan aktif', () {
      final List<MyMedicineSchedule> options =
          RefillMedicineOptions.fromSchedules(
        <MyMedicineSchedule>[
          _schedule(medicineId: 1, name: 'Promag'),
          // Obat dari pengobatan lain milik pasien tidak boleh ikut.
          _schedule(id: 2, treatmentId: 99, medicineId: 5, name: 'Omeprazole'),
        ],
        treatmentId: 7,
      );

      expect(options.map((MyMedicineSchedule e) => e.displayName), <String>[
        'Promag',
      ]);
    });

    test('8: satu obat dengan beberapa jam minum hanya muncul sekali', () {
      final List<MyMedicineSchedule> options =
          RefillMedicineOptions.fromSchedules(
        <MyMedicineSchedule>[
          _schedule(id: 1, medicineId: 1, name: 'Promag', drinkTime: '08:00:00'),
          _schedule(id: 2, medicineId: 1, name: 'Promag', drinkTime: '20:00:00'),
          _schedule(id: 3, medicineId: 2, name: 'Paracetamol'),
        ],
      );

      expect(options.length, 2);
      expect(options.map((MyMedicineSchedule e) => e.medicineId), <int>[1, 2]);
    });

    test('6: pencarian menyaring berdasarkan nama obat', () {
      final List<MyMedicineSchedule> options = <MyMedicineSchedule>[
        _schedule(medicineId: 1, name: 'Promag'),
        _schedule(id: 2, medicineId: 2, name: 'Paracetamol'),
        _schedule(id: 3, medicineId: 3, name: 'Amoxicillin'),
      ];

      expect(
        RefillMedicineOptions.search(options, 'para')
            .map((MyMedicineSchedule e) => e.displayName),
        <String>['Paracetamol'],
      );
      expect(RefillMedicineOptions.search(options, '  ').length, 3);
      expect(RefillMedicineOptions.search(options, 'zzz'), isEmpty);
    });
  });

  group('Aturan jumlah dan validasi kirim', () {
    test('9: jumlah permintaan selalu 30', () {
      expect(RefillFormValidation.fixedQuantity, 30);
    });

    test('12: body permintaan hanya memuat satu medicine_id', () {
      final Map<String, dynamic> body = Refill.createRequestBody(
        treatmentId: 7,
        medicineId: 2,
        quantity: RefillFormValidation.fixedQuantity,
        reason: 'Obat Hilang',
      );

      expect(body, <String, dynamic>{
        'treatment_id': 7,
        'medicine_id': 2,
        'quantity': 30,
        'reason': 'Obat Hilang',
      });
      expect(body['medicine_id'], isA<int>());
    });

    test('kirim nonaktif tanpa obat, tanpa alasan, atau tanpa centang', () {
      expect(
        RefillFormValidation.canSubmitSingle(
          hasTreatment: true,
          hasMedicine: false,
          reason: 'Obat Hilang',
          confirmed: true,
        ),
        isFalse,
      );
      expect(
        RefillFormValidation.canSubmitSingle(
          hasTreatment: true,
          hasMedicine: true,
          reason: null,
          confirmed: true,
        ),
        isFalse,
      );
      expect(
        RefillFormValidation.canSubmitSingle(
          hasTreatment: true,
          hasMedicine: true,
          reason: 'Obat Hilang',
          confirmed: false,
        ),
        isFalse,
      );
      expect(
        RefillFormValidation.canSubmitSingle(
          hasTreatment: true,
          hasMedicine: true,
          reason: 'Obat Hilang',
          confirmed: true,
        ),
        isTrue,
      );
    });
  });

  group('Widget pemilihan obat', () {
    testWidgets('1 & 2: satu jenis obat tampil langsung tanpa dropdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefillMedicinePicker(
              options: <MyMedicineSchedule>[
                _schedule(medicineId: 1, name: 'Promag'),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(RefillMedicinePicker.singleOptionTitle), findsOneWidget);
      expect(find.text(RefillMedicinePicker.title), findsNothing);
      expect(find.text('Promag'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

      // Menekan kartu tidak membuka daftar pilihan.
      await tester.tap(find.text('Promag'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('3 & 7: lebih dari satu jenis obat memakai dropdown satu pilihan',
        (WidgetTester tester) async {
      MyMedicineSchedule? picked;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return RefillMedicinePicker(
                  options: <MyMedicineSchedule>[
                    _schedule(medicineId: 1, name: 'Promag'),
                    _schedule(id: 2, medicineId: 2, name: 'Paracetamol'),
                    _schedule(id: 3, medicineId: 3, name: 'Amoxicillin'),
                  ],
                  selected: picked,
                  onSelected: (MyMedicineSchedule? value) {
                    setState(() => picked = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(RefillMedicinePicker.title), findsOneWidget);
      expect(find.text(RefillMedicinePicker.placeholder), findsOneWidget);

      await tester.tap(find.text(RefillMedicinePicker.placeholder));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Paracetamol'));
      await tester.pumpAndSettle();

      expect(picked?.medicineId, 2);
      // Satu obat saja yang menempel pada field, bukan kumpulan chip.
      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('Promag'), findsNothing);
      expect(find.text('Amoxicillin'), findsNothing);
    });

    testWidgets('6: pencarian di dalam dropdown menyaring daftar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefillMedicinePicker(
              options: <MyMedicineSchedule>[
                _schedule(medicineId: 1, name: 'Promag'),
                _schedule(id: 2, medicineId: 2, name: 'Paracetamol'),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text(RefillMedicinePicker.placeholder));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'prom');
      await tester.pumpAndSettle();

      expect(find.text('Promag'), findsOneWidget);
      expect(find.text('Paracetamol'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(RefillMedicinePicker.noMatchLabel), findsOneWidget);
    });

    testWidgets('10: tidak ada kontrol jumlah yang dapat diedit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefillMedicinePicker(
              options: <MyMedicineSchedule>[
                _schedule(medicineId: 1, name: 'Promag'),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Jumlah yang Diminta'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(
        find.text(RefillMedicinePicker.quantityInfo),
        findsOneWidget,
      );
    });

    testWidgets('20: nama obat panjang tidak melimpah',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefillMedicinePicker(
              options: <MyMedicineSchedule>[
                _schedule(
                  medicineId: 1,
                  name:
                      'Kombinasi Rifampisin Isoniazid Pirazinamid Etambutol '
                      'Lepas Lambat Kemasan Besar',
                ),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Ringkasan', () {
    testWidgets('11: ringkasan mengikuti obat dan alasan terpilih',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RefillSummarySection(
              medicineName: 'Paracetamol',
              quantity: RefillFormValidation.fixedQuantity,
              reason: 'Obat Hilang',
            ),
          ),
        ),
      );

      expect(find.text('Paracetamol'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Obat Hilang'), findsOneWidget);
    });

    testWidgets('ringkasan tanpa pilihan menampilkan Belum dipilih',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RefillSummarySection(
              medicineName: null,
              quantity: RefillFormValidation.fixedQuantity,
            ),
          ),
        ),
      );

      expect(find.text('Belum dipilih'), findsNWidgets(2));
      expect(find.text('30'), findsOneWidget);
    });
  });

  group('Halaman Pesan Ulang Obat', () {
    testWidgets('obat tunggal terisi otomatis dan masuk ringkasan',
        (WidgetTester tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        _refillPage(
          schedules: <MyMedicineSchedule>[
            _schedule(medicineId: 1, name: 'Promag', drinkTime: '08:00:00'),
            _schedule(id: 2, medicineId: 1, name: 'Promag', drinkTime: '20:00:00'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(RefillMedicinePicker.singleOptionTitle), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      // Satu kali pada field, satu kali pada ringkasan.
      expect(find.text('Promag'), findsNWidgets(2));
      expect(find.text('Belum dipilih'), findsOneWidget);
    });

    testWidgets('12: satu kiriman menghasilkan satu request satu obat',
        (WidgetTester tester) async {
      _useTallScreen(tester);
      final _RecordingRefillService refillService = _RecordingRefillService();

      await tester.pumpWidget(
        _refillPage(
          schedules: <MyMedicineSchedule>[
            _schedule(medicineId: 1, name: 'Promag'),
          ],
          refillService: refillService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Obat Hilang'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Permintaan'));
      await tester.pumpAndSettle();

      expect(refillService.requests, <Map<String, dynamic>>[
        <String, dynamic>{
          'treatment_id': 7,
          'medicine_id': 1,
          'quantity': 30,
          'reason': 'Obat Hilang',
        },
      ]);
    });

    testWidgets('kirim tidak aktif sebelum alasan dan pernyataan lengkap',
        (WidgetTester tester) async {
      _useTallScreen(tester);
      final _RecordingRefillService refillService = _RecordingRefillService();

      await tester.pumpWidget(
        _refillPage(
          schedules: <MyMedicineSchedule>[
            _schedule(medicineId: 1, name: 'Promag'),
          ],
          refillService: refillService,
        ),
      );
      await tester.pumpAndSettle();

      FilledButton submitButton() =>
          tester.widget<FilledButton>(find.byType(FilledButton).first);

      expect(submitButton().onPressed, isNull);

      await tester.tap(find.text('Obat Hilang'));
      await tester.pumpAndSettle();
      expect(submitButton().onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(submitButton().onPressed, isNotNull);

      expect(refillService.requests, isEmpty);
    });

    testWidgets('15: gagal memuat daftar obat tidak membuat aplikasi jatuh',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _refillPage(
          schedules: <MyMedicineSchedule>[],
          scheduleError: const ApiException('Jaringan terputus.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Jaringan terputus.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byType(FilledButton).first)
            .onPressed,
        isNull,
      );
    });
  });

  group('Halaman Informasi Obat', () {
    testWidgets('13 & 14: tanpa kartu stok dan tanpa navigasi dari daftar obat',
        (WidgetTester tester) async {
      _useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MedicinePage(
            scheduleService: _FakeScheduleService(
              schedules: <MyMedicineSchedule>[
                _schedule(medicineId: 1, name: 'Promag'),
              ],
            ),
            controlScheduleService: _FakeControlScheduleService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stok Obat Saat Ini'), findsNothing);
      expect(find.text('12 / 30'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      expect(find.text('DAFTAR OBAT AKTIF'), findsOneWidget);
      expect(find.text('Promag'), findsOneWidget);

      await tester.tap(find.text('Promag'));
      await tester.pumpAndSettle();

      // Masih di halaman Obat: tidak ada rute baru yang terbuka.
      expect(find.text('DAFTAR OBAT AKTIF'), findsOneWidget);
      expect(find.text('Promag'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
