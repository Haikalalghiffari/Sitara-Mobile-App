import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/core/network/api_exception.dart';
import 'package:sitara/features/medicine/models/refill.dart';
import 'package:sitara/features/medicine/utils/refill_form_validation.dart';
import 'package:sitara/features/medicine/widgets/refill_history_section.dart';
import 'package:sitara/features/medicine/widgets/refill_medicine_info_card.dart';

Refill _refill({
  int id = 1,
  String status = 'pending',
  int quantity = 10,
}) {
  return Refill(
    id: id,
    treatmentId: 3,
    medicineId: 9,
    quantity: quantity,
    reason: 'Obat Habis',
    description: null,
    status: status,
    nurseNote: null,
    approvedBy: null,
    approvedAt: null,
    isActive: true,
    createdAt: '2026-08-26T10:00:00',
    updatedAt: '2026-08-26T10:00:00',
  );
}

void main() {
  test('patient history uses GET /refills/my not GET /refills', () {
    expect(ApiEndpoints.myRefills, '/refills/my');
    expect(ApiEndpoints.refills, '/refills');
    expect(ApiEndpoints.myRefills, isNot(ApiEndpoints.refills));
  });

  test('Refill.fromJson parses RefillResponse without medicine_name', () {
    final Refill refill = Refill.fromJson(<String, dynamic>{
      'id': 4,
      'treatment_id': 3,
      'medicine_id': 9,
      'quantity': 8,
      'reason': 'Obat Habis',
      'description': null,
      'status': 'pending',
      'nurse_note': null,
      'approved_by': null,
      'approved_at': null,
      'is_active': true,
      'created_at': '2026-08-26T10:00:00',
      'updated_at': '2026-08-26T10:00:00',
    });

    expect(refill.id, 4);
    expect(refill.medicineId, 9);
    expect(refill.status, 'pending');
    expect(refill.statusLabel, 'Menunggu');
  });

  test('POST success refresh stays on GET /refills/my', () {
    expect(ApiEndpoints.myRefills, '/refills/my');
    expect(RefillHistoryFetch.skipDuplicate(inFlight: false), isFalse);
  });

  test('POST /refills body mengikuti RefillCreate, description opsional', () {
    expect(
      Refill.createRequestBody(
        treatmentId: 3,
        medicineId: 9,
        quantity: 2,
        reason: 'Obat Hilang',
      ),
      <String, dynamic>{
        'treatment_id': 3,
        'medicine_id': 9,
        'quantity': 2,
        'reason': 'Obat Hilang',
      },
    );

    expect(
      Refill.createRequestBody(
        treatmentId: 3,
        medicineId: 9,
        quantity: 2,
        reason: 'Obat Hilang',
        description: '   ',
      ).containsKey('description'),
      isFalse,
    );

    expect(
      Refill.createRequestBody(
        treatmentId: 3,
        medicineId: 9,
        quantity: 2,
        reason: 'Obat Hilang',
        description: 'Keterangan tambahan',
      )['description'],
      'Keterangan tambahan',
    );
  });

  testWidgets('empty refill history is not an API error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(refills: <Refill>[]),
        ),
      ),
    );

    expect(find.text('Belum ada riwayat permintaan obat.'), findsOneWidget);
    expect(find.text('Gagal memuat riwayat.'), findsNothing);
    expect(find.text(ApiException.connectionFailedMessage), findsNothing);
  });

  testWidgets('refill 403 is error state not empty history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(
            errorMessage: 'Anda tidak memiliki akses ke layanan ini.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Gagal memuat riwayat.'), findsOneWidget);
    expect(find.text('Anda tidak memiliki akses ke layanan ini.'), findsOneWidget);
    expect(find.text('Belum ada riwayat permintaan obat.'), findsNothing);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('tanpa riwayat tidak menampilkan chip status kosong',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RefillMedicineInfoCard(),
        ),
      ),
    );

    expect(find.textContaining('Belum ada permintaan'), findsNothing);
    expect(find.textContaining('Status:'), findsNothing);
  });

  testWidgets('loading history is not empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(isLoading: true),
        ),
      ),
    );

    expect(find.text('Memuat riwayat...'), findsOneWidget);
    expect(find.text('Belum ada riwayat permintaan obat.'), findsNothing);
    expect(find.text('Gagal memuat riwayat.'), findsNothing);
  });

  testWidgets('200 with refill data renders history not empty state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(
            refills: <Refill>[_refill()],
          ),
        ),
      ),
    );

    expect(find.text('Jumlah diminta: 10'), findsOneWidget);
    expect(find.text('Alasan: Obat Habis'), findsOneWidget);
    expect(find.text('Belum ada riwayat permintaan obat.'), findsNothing);
    expect(find.text('Gagal memuat riwayat.'), findsNothing);
  });

  testWidgets('retry control is present on history error', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(
            errorMessage: 'Jaringan terputus.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Coba Lagi'));
    expect(retried, isTrue);
  });

  testWidgets('empty history shows Pesan Ulang Obat CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefillHistorySection(
            refills: const <Refill>[],
            onStartRequest: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pesan Ulang Obat'));
    expect(tapped, isTrue);
  });
}
