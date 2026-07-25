import 'package:flutter/material.dart';

/// Token border radius SITARA (Material 3 shape system).
abstract final class AppRadius {
  // ── Base scale ───────────────────────────────────────────────────────────
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double full = 999;

  // ── BorderRadius helpers ─────────────────────────────────────────────────
  static BorderRadius get noneRadius => BorderRadius.circular(none);
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get xxxlRadius => BorderRadius.circular(xxxl);
  static BorderRadius get fullRadius => BorderRadius.circular(full);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Input field, chip kecil.
  static BorderRadius get input => lgRadius;

  /// Button, input field standar.
  static BorderRadius get component => mdRadius;

  /// Card, dialog.
  static BorderRadius get card => xlRadius;

  /// Card besar (timer, hero).
  static BorderRadius get cardLarge => xxlRadius;

  /// Tombol pill (Masuk, Daftar).
  static BorderRadius get button => fullRadius;

  /// Bottom sheet.
  static BorderRadius get bottomSheet => BorderRadius.only(
        topLeft: Radius.circular(xxl),
        topRight: Radius.circular(xxl),
      );

  /// Navigation bar indicator pill.
  static BorderRadius get navIndicator => fullRadius;

  /// Icon container kecil.
  static BorderRadius get iconContainer => smRadius;
}
