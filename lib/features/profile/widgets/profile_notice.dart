import 'package:flutter/material.dart';

/// Backend hanya menyediakan `GET /patients/profile`. Tidak ada endpoint yang
/// memungkinkan pasien memperbarui datanya sendiri, dan tidak ada endpoint
/// unggah foto profil, sehingga tombol ubah pada halaman profil belum punya
/// tujuan.
const String profileEditUnavailableMessage =
    'Ubah data profil belum tersedia di aplikasi. '
    'Hubungi petugas kesehatan untuk memperbarui data Anda.';

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
