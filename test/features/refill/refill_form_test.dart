import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/medicine/models/refill.dart';
import 'package:sitara/features/medicine/utils/refill_form_validation.dart';

void main() {
  test('first history fetch is not skipped while the spinner is already showing',
      () {
    const bool uiLoading = true;
    const bool inFlight = false;

    expect(uiLoading, isTrue);
    expect(RefillHistoryFetch.skipDuplicate(inFlight: inFlight), isFalse);
    expect(RefillHistoryFetch.skipDuplicate(inFlight: true), isTrue);
  });

  test('duplicate tap only locks once', () {
    final RefillSubmitLock lock = RefillSubmitLock();
    expect(lock.tryLock(), isTrue);
    expect(lock.tryLock(), isFalse);
    expect(lock.isLocked, isTrue);
    lock.unlock();
    expect(lock.tryLock(), isTrue);
  });

  test('jumlah 0 atau negatif tidak valid', () {
    expect(
      RefillFormValidation.validate(
        hasTreatment: true,
        hasMedicine: true,
        reason: 'Obat Hilang',
        quantity: 0,
        confirmed: true,
      ),
      isNotNull,
    );
    expect(
      RefillFormValidation.validate(
        hasTreatment: true,
        hasMedicine: true,
        reason: 'Obat Hilang',
        quantity: -1,
        confirmed: true,
      ),
      isNotNull,
    );
  });

  test('form invalid tidak menghasilkan request body', () {
    final String? error = RefillFormValidation.validate(
      hasTreatment: true,
      hasMedicine: true,
      reason: null,
      quantity: 2,
      confirmed: true,
    );
    expect(error, isNotNull);
    expect(error, contains('alasan'));
  });

  test('form valid boleh membangun body POST /refills', () {
    expect(
      RefillFormValidation.validate(
        hasTreatment: true,
        hasMedicine: true,
        reason: 'Obat Hilang',
        quantity: 2,
        confirmed: true,
      ),
      isNull,
    );
    expect(
      Refill.createRequestBody(
        treatmentId: 1,
        medicineId: 4,
        quantity: 2,
        reason: 'Obat Hilang',
      ),
      containsPair('quantity', 2),
    );
  });
}
