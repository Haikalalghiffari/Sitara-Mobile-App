import 'package:flutter/material.dart';

/// Backend hanya menyediakan `GET /patients/profile`. Tidak ada
/// `PUT /patients/profile` untuk pasien. `PUT /patients/{patient_id}` adalah
/// endpoint pembaruan rekam pasien secara umum, bukan endpoint profil pasien.
const String profileEditUnavailableMessage =
    'Nomor telepon dan alamat belum dapat disimpan dari aplikasi. '
    'Hubungi petugas kesehatan untuk memperbarui data Anda.';

const String profilePictureUploadUnavailableMessage =
    'Foto profil belum dapat disimpan ke server. '
    'Anda tetap dapat memilih foto dari kamera atau galeri.';

const String profileSettingsUnavailableMessage =
    'Pengaturan pada halaman ini belum tersedia.';

/// Menggantikan callback kosong pada tombol yang belum didukung backend.
///
/// Lebih baik menyatakan keterbatasan secara terbuka daripada membiarkan tombol
/// yang ditekan tanpa reaksi, karena pengguna akan menganggap aplikasi rusak.
void showProfileNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}
