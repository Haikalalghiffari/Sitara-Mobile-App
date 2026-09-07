import '../models/my_medicine_schedule.dart';

/// Daftar obat yang boleh dipilih untuk `POST /refills`.
///
/// Sumber: `GET /medicine-schedules/my`. Satu `medicine_id` dengan beberapa
/// jam minum hanya muncul sekali.
class RefillMedicineOptions {
  const RefillMedicineOptions._();

  static List<MyMedicineSchedule> fromSchedules(
    List<MyMedicineSchedule> schedules, {
    int? treatmentId,
  }) {
    final List<MyMedicineSchedule> pool = treatmentId == null
        ? List<MyMedicineSchedule>.from(schedules)
        : schedules
            .where((MyMedicineSchedule item) => item.treatmentId == treatmentId)
            .toList();

    final Map<int, MyMedicineSchedule> unique = <int, MyMedicineSchedule>{};
    for (final MyMedicineSchedule item in pool) {
      if (item.medicineId <= 0) continue;
      unique.putIfAbsent(item.medicineId, () => item);
    }
    return unique.values.toList();
  }

  /// Stok yang dikunci sebagai quantity refill.
  ///
  /// Memakai `quantity_remaining` dari jadwal yang dipilih. Bila 0, memakai
  /// `quantity_initial` bila masih valid. 0 berarti stok tidak tersedia.
  static int stockQuantity(MyMedicineSchedule? medicine) {
    if (medicine == null) return 0;
    if (medicine.quantityRemaining > 0) return medicine.quantityRemaining;
    if (medicine.quantityInitial > 0) return medicine.quantityInitial;
    return 0;
  }
}
