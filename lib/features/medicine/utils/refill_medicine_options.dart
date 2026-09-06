import '../models/my_medicine_schedule.dart';

/// Pilihan obat pada form pesan ulang.
///
/// Sumbernya `GET /medicine-schedules/my`, yaitu obat yang benar-benar
/// diresepkan kepada pasien yang sedang login. Tidak ada daftar obat statis di
/// aplikasi. Endpoint ini juga satu-satunya sumber yang aman: `POST /refills`
/// mewajibkan pasangan `treatment_id` dan `medicine_id` milik pasien tersebut.
class RefillMedicineOptions {
  const RefillMedicineOptions._();

  /// Satu baris per obat.
  ///
  /// Jadwal dengan `medicine_id` sama, misalnya obat yang diminum dua kali
  /// sehari, hanya muncul sekali agar pasien tidak melihat nama ganda.
  ///
  /// [treatmentId] menyaring ke pengobatan aktif supaya pasangan id yang
  /// dikirim berasal dari satu pengobatan, bukan dua pengobatan berbeda.
  static List<MyMedicineSchedule> fromSchedules(
    List<MyMedicineSchedule> schedules, {
    int? treatmentId,
  }) {
    final List<MyMedicineSchedule> options = <MyMedicineSchedule>[];
    final Set<int> seenMedicineIds = <int>{};

    for (final MyMedicineSchedule item in schedules) {
      if (treatmentId != null && item.treatmentId != treatmentId) continue;
      if (item.medicineId <= 0) continue;
      if (!seenMedicineIds.add(item.medicineId)) continue;
      options.add(item);
    }

    return options;
  }

  /// Pencarian lokal atas daftar yang sudah diambil, tanpa request tambahan.
  static List<MyMedicineSchedule> search(
    List<MyMedicineSchedule> options,
    String query,
  ) {
    final String keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return List<MyMedicineSchedule>.of(options);

    return options
        .where(
          (MyMedicineSchedule item) =>
              item.displayName.toLowerCase().contains(keyword),
        )
        .toList();
  }
}
