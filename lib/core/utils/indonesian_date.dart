/// Format tanggal berbahasa Indonesia tanpa dependensi tambahan.
///
/// Paket `intl` tidak dipakai project ini, jadi nama bulan ditulis langsung
/// agar tidak ada penambahan dependensi hanya untuk satu format.
const List<String> _monthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// `21 Agustus 2026`, null bila tanggalnya tidak ada.
String? formatIndonesianDate(DateTime? date) {
  if (date == null) return null;
  if (date.month < 1 || date.month > 12) return null;

  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}
