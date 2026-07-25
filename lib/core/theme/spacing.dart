/// Skala spacing SITARA berbasis grid 4px (Material 3).
abstract final class AppSpacing {
  // ── Base scale ───────────────────────────────────────────────────────────
  static const double none = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;
  static const double giant = 80;

  // ── Layout ───────────────────────────────────────────────────────────────
  /// Padding horizontal standar layar.
  static const double screenHorizontal = lg;

  /// Padding vertikal standar layar.
  static const double screenVertical = xl;

  /// Lebar maksimum konten (tablet/desktop).
  static const double contentMaxWidth = 480;

  /// Jarak antar section.
  static const double section = xxl;

  /// Jarak antar section besar.
  static const double sectionLarge = xxxl;

  // ── Komponen ─────────────────────────────────────────────────────────────
  /// Padding dalam card standar.
  static const double cardPadding = xl;

  /// Padding dalam card kecil.
  static const double cardPaddingSmall = lg;

  /// Jarak antar item dalam list.
  static const double listItem = sm;

  /// Jarak antar elemen form.
  static const double formField = lg;

  /// Tinggi minimum area tap (Material accessibility).
  static const double minTouchTarget = 48;

  /// Tinggi tombol standar.
  static const double buttonHeight = 52;

  /// Tinggi bottom navigation bar.
  static const double bottomNavHeight = 72;

  /// Tinggi app bar.
  static const double appBarHeight = 56;

  /// Ukuran ikon kecil.
  static const double iconSm = 16;

  /// Ukuran ikon standar.
  static const double iconMd = 20;

  /// Ukuran ikon besar.
  static const double iconLg = 24;

  /// Ukuran ikon extra large.
  static const double iconXl = 36;
}
