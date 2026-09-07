import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/medicine/models/my_medicine_schedule.dart';
import 'package:sitara/features/medicine/models/refill.dart';
import 'package:sitara/features/medicine/utils/refill_form_validation.dart';
import 'package:sitara/features/medicine/utils/refill_medicine_options.dart';
import 'package:sitara/features/medicine/widgets/refill_medicine_picker.dart';
import 'package:sitara/features/medicine/widgets/refill_quantity_field.dart';
import 'package:sitara/features/medicine/widgets/refill_summary_section.dart';

MyMedicineSchedule _med({
  required int id,
  required String name,
  int remaining = 30,
  int initial = 30,
  int treatmentId = 1,
}) {
  return MyMedicineSchedule(
    treatmentId: treatmentId,
    medicineId: id,
    medicineName: name,
    dosage: '1 tablet',
    quantityInitial: initial,
    quantityRemaining: remaining,
    drinkTime: '08:00:00',
  );
}

void main() {
  test('1. no active medicine', () {
    expect(RefillMedicineOptions.fromSchedules(const []), isEmpty);
    expect(RefillMedicineOptions.stockQuantity(null), 0);
  });

  test('2. one medicine', () {
    final List<MyMedicineSchedule> options = RefillMedicineOptions.fromSchedules(
      <MyMedicineSchedule>[_med(id: 1, name: 'Promag')],
    );
    expect(options, hasLength(1));
    expect(options.first.displayName, 'Promag');
  });

  test('3. multiple medicines unique by medicine_id', () {
    final List<MyMedicineSchedule> options = RefillMedicineOptions.fromSchedules(
      <MyMedicineSchedule>[
        _med(id: 1, name: 'Promag', remaining: 30),
        _med(id: 1, name: 'Promag', remaining: 30, initial: 30),
        _med(id: 2, name: 'Paracetamol', remaining: 20),
      ],
    );
    expect(options, hasLength(2));
    expect(options.map((MyMedicineSchedule item) => item.displayName), [
      'Promag',
      'Paracetamol',
    ]);
  });

  test('5-7. quantity mengikuti stok dan tidak boleh di luar batas', () {
    final MyMedicineSchedule a = _med(id: 1, name: 'Promag', remaining: 30);
    final MyMedicineSchedule b = _med(id: 2, name: 'Paracetamol', remaining: 20);

    expect(RefillMedicineOptions.stockQuantity(a), 30);
    expect(RefillMedicineOptions.stockQuantity(b), 20);

    expect(
      RefillFormValidation.validateLockedQuantity(quantity: 30, stock: 30),
      isNull,
    );
    expect(
      RefillFormValidation.validateLockedQuantity(quantity: 31, stock: 30),
      isNotNull,
    );
    expect(
      RefillFormValidation.validateLockedQuantity(quantity: 29, stock: 30),
      isNotNull,
    );
    expect(
      RefillFormValidation.validateLockedQuantity(quantity: 0, stock: 30),
      isNotNull,
    );
    expect(
      RefillFormValidation.validateLockedQuantity(quantity: -1, stock: 30),
      isNotNull,
    );
    expect(
      RefillFormValidation.validateLockedQuantity(quantity: 20, stock: 0),
      isNotNull,
    );
  });

  test('11. submit payload matches summary', () {
    final MyMedicineSchedule medicine = _med(
      id: 4,
      name: 'Promag',
      remaining: 30,
    );
    const String reason = 'Obat Hilang';
    final int quantity = RefillMedicineOptions.stockQuantity(medicine);

    expect(
      Refill.createRequestBody(
        treatmentId: medicine.treatmentId,
        medicineId: medicine.medicineId,
        quantity: quantity,
        reason: reason,
      ),
      <String, dynamic>{
        'treatment_id': 1,
        'medicine_id': 4,
        'quantity': 30,
        'reason': 'Obat Hilang',
      },
    );
  });

  testWidgets('4. dropdown selection untuk lebih dari satu obat', (
    WidgetTester tester,
  ) async {
    MyMedicineSchedule? selected;
    final List<MyMedicineSchedule> options = <MyMedicineSchedule>[
      _med(id: 1, name: 'Promag', remaining: 30),
      _med(id: 2, name: 'Paracetamol', remaining: 20),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return RefillMedicinePicker(
                options: options,
                selected: selected,
                onSelected: (MyMedicineSchedule? value) {
                  setState(() => selected = value);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Pilih obat yang akan dipesan ulang'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol').last);
    await tester.pumpAndSettle();
    expect(selected?.displayName, 'Paracetamol');
    expect(RefillMedicineOptions.stockQuantity(selected), 20);
  });

  test('12. form valid boleh submit dengan quantity = stok', () {
    expect(
      RefillFormValidation.canSubmitSingle(
        hasTreatment: true,
        hasMedicine: true,
        reason: 'Obat Hilang',
        confirmed: true,
        quantity: 30,
        stock: 30,
      ),
      isTrue,
    );
  });

  test('13. form gagal bila stok tidak valid', () {
    expect(
      RefillFormValidation.canSubmitSingle(
        hasTreatment: true,
        hasMedicine: true,
        reason: 'Obat Hilang',
        confirmed: true,
        quantity: 30,
        stock: 0,
      ),
      isFalse,
    );
  });

  testWidgets('8-10. summary menampilkan pilihan', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RefillSummarySection(
            medicineName: 'Promag',
            quantity: 30,
            reason: 'Obat Hilang',
          ),
        ),
      ),
    );

    expect(find.text('Promag'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Obat Hilang'), findsOneWidget);
  });

  testWidgets('quantity field terkunci ke stok', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RefillQuantityField(quantity: 30, stock: 30),
        ),
      ),
    );

    expect(find.text('30'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });
}
