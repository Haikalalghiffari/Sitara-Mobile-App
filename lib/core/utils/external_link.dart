import 'package:url_launcher/url_launcher.dart';

/// Pembuka URL eksternal, dipakai agar widget dapat diuji tanpa platform.
typedef ExternalUrlOpener = Future<bool> Function(Uri url);

/// Membuka tautan di aplikasi luar (browser, Google Maps, dan sejenisnya).
///
/// Tidak ada peta yang disematkan di dalam aplikasi: tautan diserahkan ke
/// aplikasi yang sudah terpasang di perangkat.
class ExternalLink {
  const ExternalLink._();

  /// `true` bila sistem menerima tautannya. Kegagalan dilaporkan sebagai
  /// `false` supaya pemanggil dapat menampilkan pesan, bukan melempar error
  /// mentah ke pengguna.
  static Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
