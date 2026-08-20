/// Response `MyMedicineScheduleResponse` dari `GET /medicine-schedules/my`.
///
/// Field mengikuti persis schema backend, tanpa tambahan. Backend tidak
/// mengirim id jadwal, satuan obat, maupun jumlah dosis per hari.
class MyMedicineSchedule {
  const MyMedicineSchedule({
    this.id = 0,
    required this.treatmentId,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.quantityInitial,
    required this.quantityRemaining,
    required this.drinkTime,
  });

  final int id;
  final int treatmentId;

  /// Dipakai POST /refills, bukan untuk ditampilkan sebagai nama obat.
  final int medicineId;

  /// Nama dari field `medicine_name` pada response. Bukan hasil mapping
  /// `medicine_id` di aplikasi.
  final String medicineName;

  /// Teks bebas dari petugas (`max_length=100`), misalnya aturan pakai.
  /// Formatnya tidak dijamin, jadi tidak diurai menjadi angka apa pun.
  final String dosage;

  final int quantityInitial;
  final int quantityRemaining;

  /// Tipe backend `time`, dikirim sebagai `HH:MM:SS` tanpa zona waktu.
  final String drinkTime;

  factory MyMedicineSchedule.fromJson(Map<String, dynamic> json) {
    return MyMedicineSchedule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      treatmentId: (json['treatment_id'] as num?)?.toInt() ?? 0,
      medicineId: (json['medicine_id'] as num?)?.toInt() ?? 0,
      medicineName: json['medicine_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      quantityInitial: (json['quantity_initial'] as num?)?.toInt() ?? 0,
      quantityRemaining: (json['quantity_remaining'] as num?)?.toInt() ?? 0,
      drinkTime: json['drink_time']?.toString() ?? '',
    );
  }

  /// 0.0 sampai 1.0 untuk [LinearProgressIndicator].
  ///
  /// Bernilai null bila `quantity_initial` tidak masuk akal, agar UI memilih
  /// empty state ketimbang menampilkan rasio yang menyesatkan.
  double? get remainingFraction {
    if (quantityInitial <= 0) return null;

    final double value = quantityRemaining / quantityInitial;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  /// Menit sejak tengah malam, dipakai untuk mengurutkan jadwal.
  ///
  /// Null bila `drink_time` tidak dapat dibaca, sehingga jadwal tersebut
  /// tidak ikut dipilih sebagai jadwal berikutnya.
  int? get drinkMinutesOfDay {
    final List<String> parts = drinkTime.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return hour * 60 + minute;
  }

  /// `10.30` dari `10:30:00`.
  ///
  /// Detik dibuang dan label zona waktu sengaja tidak ditambahkan karena
  /// backend mengirim jam polos tanpa informasi zona.
  String? get drinkTimeLabel {
    final int? minutes = drinkMinutesOfDay;
    if (minutes == null) return null;

    final String hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final String minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Nama yang ditampilkan di UI.
  ///
  /// Tidak pernah memakai `medicine_id`. Bila `medicine_name` kosong, fallback
  /// netral dipakai supaya label "Obat #1" tidak muncul lagi.
  String get displayName {
    final String name = medicineName.trim();
    if (name.isEmpty) return 'Nama obat belum tersedia';
    return name;
  }

  /// Nama tampilan dari jadwal obat yang sudah diambil lewat
  /// `GET /medicine-schedules/my`. Bukan mapping hardcode `medicine_id`.
  static String nameForId(
    List<MyMedicineSchedule> schedules,
    int medicineId,
  ) {
    for (final MyMedicineSchedule item in schedules) {
      if (item.medicineId == medicineId) return item.displayName;
    }
    return 'Nama obat belum tersedia';
  }

  /// Kapan `drink_time` berikutnya jatuh, dalam zona waktu perangkat.
  ///
  /// `drink_time` berulang setiap hari dan dikirim tanpa informasi zona, jadi
  /// jamnya dipasang apa adanya pada tanggal perangkat tanpa konversi UTC.
  /// Bila jam hari ini sudah lewat, tanggalnya digeser ke hari berikutnya.
  DateTime? nextOccurrence({DateTime? now}) {
    final int? minutes = drinkMinutesOfDay;
    if (minutes == null) return null;

    final DateTime reference = now ?? DateTime.now();

    final DateTime todaySchedule = DateTime(
      reference.year,
      reference.month,
      reference.day,
      minutes ~/ 60,
      minutes % 60,
    );

    if (!todaySchedule.isBefore(reference)) return todaySchedule;

    // Lewat hari lewat konstruktor DateTime, bukan penjumlahan Duration,
    // agar pergantian bulan dan tahun tetap benar.
    return DateTime(
      reference.year,
      reference.month,
      reference.day + 1,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  /// Jadwal dengan sisa stok paling menipis secara proporsional.
  ///
  /// Kuantitas antar obat sengaja tidak dijumlahkan karena satuan tiap obat
  /// tidak dikirim backend, sehingga totalnya tidak bermakna.
  static MyMedicineSchedule? selectLowestStock(
    List<MyMedicineSchedule> schedules,
  ) {
    if (schedules.isEmpty) return null;

    final List<MyMedicineSchedule> measurable = schedules
        .where((MyMedicineSchedule item) => item.remainingFraction != null)
        .toList();

    if (measurable.isEmpty) return null;

    measurable.sort((MyMedicineSchedule a, MyMedicineSchedule b) {
      return a.remainingFraction!.compareTo(b.remainingFraction!);
    });

    return measurable.first;
  }

  /// Jadwal minum terdekat dihitung dari jam perangkat.
  ///
  /// Bila seluruh jam hari ini sudah lewat, jadwal paling awal dipakai karena
  /// `drink_time` berulang setiap hari.
  static MyMedicineSchedule? selectNextDrink(
    List<MyMedicineSchedule> schedules, {
    DateTime? now,
  }) {
    final List<MyMedicineSchedule> timed = schedules
        .where((MyMedicineSchedule item) => item.drinkMinutesOfDay != null)
        .toList();

    if (timed.isEmpty) return null;

    timed.sort((MyMedicineSchedule a, MyMedicineSchedule b) {
      return a.drinkMinutesOfDay!.compareTo(b.drinkMinutesOfDay!);
    });

    final DateTime reference = now ?? DateTime.now();
    final int currentMinutes = reference.hour * 60 + reference.minute;

    for (final MyMedicineSchedule item in timed) {
      if (item.drinkMinutesOfDay! >= currentMinutes) return item;
    }

    return timed.first;
  }

  @override
  String toString() =>
      'MyMedicineSchedule(treatmentId: $treatmentId, '
      'medicineId: $medicineId, medicineName: $medicineName, '
      'drinkTime: $drinkTime)';
}
