import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/core/network/api_config.dart';
import 'package:sitara/features/medicine/models/refill.dart';
import 'package:sitara/features/medicine/widgets/refill_history_section.dart';
import 'package:sitara/features/medicine/widgets/refill_pickup_card.dart';

Map<String, dynamic> _refillJson({
  String status = 'approved',
  Object? pickupFacility = _sentinel,
  String? approvedAt = '2026-09-02T02:10:00',
}) {
  return <String, dynamic>{
    'id': 4,
    'treatment_id': 3,
    'medicine_id': 9,
    'quantity': 8,
    'reason': 'Obat Habis',
    'description': null,
    'status': status,
    'nurse_note': null,
    'approved_by': 2,
    'approved_at': approvedAt,
    'is_active': true,
    'created_at': '2026-09-01T10:00:00',
    'updated_at': '2026-09-02T02:10:00',
    if (pickupFacility != _sentinel) 'pickup_facility': pickupFacility,
    if (pickupFacility == _sentinel)
      'pickup_facility': <String, dynamic>{
        'id': 1,
        'name': 'Puskesmas Cibiru',
        'address': 'Jl. Raya Cibiru No. 10, Bandung',
        'phone': '022123456',
        'latitude': -6.930278,
        'longitude': 107.717222,
      },
  };
}

const Object _sentinel = Object();

Refill _refill({
  String status = 'approved',
  PickupFacility? facility,
  String? approvedAt,
}) {
  return Refill(
    id: 4,
    treatmentId: 3,
    medicineId: 9,
    quantity: 8,
    reason: 'Obat Habis',
    description: null,
    status: status,
    nurseNote: null,
    approvedBy: 2,
    approvedAt: approvedAt,
    isActive: true,
    createdAt: '2026-09-01T10:00:00',
    updatedAt: '2026-09-02T02:10:00',
    pickupFacility: facility,
  );
}

const PickupFacility _facility = PickupFacility(
  id: 1,
  name: 'Puskesmas Cibiru',
  address: 'Jl. Raya Cibiru No. 10, Bandung',
  phone: '022123456',
  latitude: -6.930278,
  longitude: 107.717222,
);

Widget _historyApp(
  Refill refill, {
  Future<bool> Function(Uri)? opener,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: RefillHistorySection(
          refills: <Refill>[refill],
          openExternalUrl: opener,
        ),
      ),
    ),
  );
}

void main() {
  test('A. RefillResponse with full pickup_facility is parsed', () {
    final Refill refill = Refill.fromJson(_refillJson());

    expect(refill.status, 'approved');
    expect(refill.isApproved, isTrue);

    final PickupFacility? facility = refill.pickupFacility;
    expect(facility, isNotNull);
    expect(facility!.id, 1);
    expect(facility.name, 'Puskesmas Cibiru');
    expect(facility.address, 'Jl. Raya Cibiru No. 10, Bandung');
    expect(facility.phone, '022123456');
    expect(facility.latitude, -6.930278);
    expect(facility.longitude, 107.717222);
    expect(facility.hasCoordinates, isTrue);
    expect(
      facility.mapsUri.toString(),
      'https://www.google.com/maps/search/?api=1&query=-6.930278%2C107.717222',
    );
    expect(ApiEndpoints.myRefills, '/refills/my');
  });

  test('A2. pickup_facility absent or null stays null, not a fake facility', () {
    expect(Refill.fromJson(_refillJson(pickupFacility: null)).pickupFacility,
        isNull);

    final Map<String, dynamic> withoutKey = _refillJson()
      ..remove('pickup_facility');
    expect(Refill.fromJson(withoutKey).pickupFacility, isNull);
    expect(Refill.fromJson(withoutKey).approvedPickupFacility, isNull);
  });

  test('A3. string coordinates from backend are parsed as double', () {
    final Refill refill = Refill.fromJson(
      _refillJson(
        pickupFacility: <String, dynamic>{
          'id': 2,
          'name': 'Puskesmas Ujungberung',
          'address': null,
          'phone': null,
          'latitude': '-6.9',
          'longitude': '107.7',
        },
      ),
    );

    expect(refill.pickupFacility!.latitude, -6.9);
    expect(refill.pickupFacility!.longitude, 107.7);
  });

  test('B. null address does not crash and has no "null" text', () {
    final Refill refill = Refill.fromJson(
      _refillJson(
        pickupFacility: <String, dynamic>{
          'id': 1,
          'name': 'Puskesmas Cibiru',
          'address': null,
          'phone': null,
          'latitude': -6.9,
          'longitude': 107.7,
        },
      ),
    );

    expect(refill.pickupFacility!.addressText, isNull);
    expect(refill.pickupFacility!.phoneText, isNull);
    expect(refill.pickupFacility!.nameText, 'Puskesmas Cibiru');
  });

  test('C. null latitude/longitude produces no maps URL', () {
    final Refill refill = Refill.fromJson(
      _refillJson(
        pickupFacility: <String, dynamic>{
          'id': 1,
          'name': 'Puskesmas Cibiru',
          'address': 'Jl. Raya Cibiru No. 10',
          'phone': null,
          'latitude': null,
          'longitude': null,
        },
      ),
    );

    final PickupFacility facility = refill.pickupFacility!;
    expect(facility.latitude, isNull);
    expect(facility.longitude, isNull);
    expect(facility.hasCoordinates, isFalse);
    expect(facility.mapsUri, isNull);
  });

  test('C2. only one coordinate present is still not mappable', () {
    final PickupFacility latOnly = PickupFacility.fromJson(
      <String, dynamic>{
        'id': 1,
        'name': 'Puskesmas Cibiru',
        'latitude': -6.9,
        'longitude': null,
      },
    );
    expect(latOnly.hasCoordinates, isFalse);
    expect(latOnly.mapsUri, isNull);

    final PickupFacility unreadable = PickupFacility.fromJson(
      <String, dynamic>{
        'id': 1,
        'name': 'Puskesmas Cibiru',
        'latitude': 'bukan-angka',
        'longitude': 'bukan-angka',
      },
    );
    expect(unreadable.latitude, isNull);
    expect(unreadable.mapsUri, isNull);
  });

  testWidgets('D. approved refill shows pickup information', (tester) async {
    await tester.pumpWidget(_historyApp(_refill(facility: _facility)));

    expect(find.text('Pengambilan Obat'), findsOneWidget);
    expect(find.text('Nama faskes'), findsOneWidget);
    expect(find.text('Puskesmas Cibiru'), findsOneWidget);
    expect(find.text('Alamat'), findsOneWidget);
    expect(find.text('Jl. Raya Cibiru No. 10, Bandung'), findsOneWidget);
    expect(find.byType(RefillPickupCard), findsOneWidget);
  });

  testWidgets('D2. null address shows a polite fallback, never "null"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _historyApp(
        _refill(
          facility: const PickupFacility(
            id: 1,
            name: 'Puskesmas Cibiru',
            address: null,
            phone: null,
            latitude: -6.9,
            longitude: 107.7,
          ),
        ),
      ),
    );

    expect(find.text(RefillPickupCard.unavailableAddress), findsOneWidget);
    expect(find.text('null'), findsNothing);
  });

  testWidgets('E. pending and rejected do not show the pickup card', (
    tester,
  ) async {
    await tester.pumpWidget(
      _historyApp(_refill(status: 'pending', facility: _facility)),
    );
    expect(find.byType(RefillPickupCard), findsNothing);
    expect(find.text('Pengambilan Obat'), findsNothing);
    expect(find.text('Buka Maps'), findsNothing);

    await tester.pumpWidget(
      _historyApp(_refill(status: 'rejected', facility: _facility)),
    );
    expect(find.byType(RefillPickupCard), findsNothing);
    expect(find.text('Pengambilan Obat'), findsNothing);
  });

  testWidgets('E2. approved without pickup_facility shows no pickup card', (
    tester,
  ) async {
    await tester.pumpWidget(_historyApp(_refill()));

    expect(find.byType(RefillPickupCard), findsNothing);
    expect(find.text('Pengambilan Obat'), findsNothing);
  });

  testWidgets('F. Buka Maps opens the Google Maps URL from coordinates', (
    tester,
  ) async {
    final List<Uri> opened = <Uri>[];

    await tester.pumpWidget(
      _historyApp(
        _refill(facility: _facility),
        opener: (Uri url) async {
          opened.add(url);
          return true;
        },
      ),
    );

    expect(find.text('Buka Maps'), findsOneWidget);
    await tester.tap(find.text('Buka Maps'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.host, 'www.google.com');
    expect(opened.single.path, '/maps/search/');
    expect(opened.single.queryParameters['api'], '1');
    expect(opened.single.queryParameters['query'], '-6.930278,107.717222');
  });

  testWidgets('F2. failed launch shows feedback instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _historyApp(
        _refill(facility: _facility),
        opener: (Uri url) async => false,
      ),
    );

    await tester.tap(find.text('Buka Maps'));
    await tester.pumpAndSettle();

    expect(find.text(RefillPickupCard.openFailedMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('G. Buka Maps is hidden when coordinates are null', (
    tester,
  ) async {
    await tester.pumpWidget(
      _historyApp(
        _refill(
          facility: const PickupFacility(
            id: 1,
            name: 'Puskesmas Cibiru',
            address: 'Jl. Raya Cibiru No. 10, Bandung',
            phone: null,
            latitude: null,
            longitude: null,
          ),
        ),
      ),
    );

    expect(find.text('Pengambilan Obat'), findsOneWidget);
    expect(find.text('Puskesmas Cibiru'), findsOneWidget);
    expect(find.text('Buka Maps'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('H. approved_at is never shown as a pickup schedule', (
    tester,
  ) async {
    final Refill refill = _refill(
      facility: _facility,
      approvedAt: '2026-09-02T02:10:00',
    );

    await tester.pumpWidget(_historyApp(refill));

    // Kartu pengambilan hanya memuat fasilitas, bukan tanggal/jam.
    expect(find.text('Pengambilan Obat'), findsOneWidget);
    expect(find.textContaining('2026-09-02'), findsNothing);
    expect(find.textContaining('02:10'), findsNothing);
    expect(find.textContaining('Jadwal'), findsNothing);
    expect(find.textContaining('Tanggal pengambilan'), findsNothing);
    expect(find.textContaining('Jam pengambilan'), findsNothing);

    // Tanggal yang tampil di kartu riwayat tetap dari `created_at`.
    expect(refill.createdAtLabel, '1 September 2026');
    expect(find.text('1 September 2026'), findsOneWidget);
  });

  test('H2. model exposes no pickup date/time field', () {
    final Refill refill = Refill.fromJson(_refillJson());

    expect(refill.approvedAt, '2026-09-02T02:10:00');
    expect(_refillJson().containsKey('pickup_date'), isFalse);
    expect(_refillJson().containsKey('pickup_time'), isFalse);
    expect(_refillJson().containsKey('pickup_datetime'), isFalse);
    expect(refill.approvedPickupFacility, isNotNull);
  });
}
