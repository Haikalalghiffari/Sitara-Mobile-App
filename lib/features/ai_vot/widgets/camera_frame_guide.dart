import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Panduan sudut pada area kamera agar pasien tahu posisi wajah dan tangan.
class CameraFrameGuide extends StatelessWidget {
  const CameraFrameGuide({
    super.key,
    this.color = AppColors.primaryLight,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerGuidePainter(color: color),
      size: Size.infinite,
    );
  }
}

class _CornerGuidePainter extends CustomPainter {
  const _CornerGuidePainter({required this.color});

  final Color color;

  static const double _armLength = 28;
  static const double _cornerRadius = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    final path = Path()
      // Kiri atas
      ..moveTo(0, _armLength)
      ..lineTo(0, _cornerRadius)
      ..quadraticBezierTo(0, 0, _cornerRadius, 0)
      ..lineTo(_armLength, 0)
      // Kanan atas
      ..moveTo(w - _armLength, 0)
      ..lineTo(w - _cornerRadius, 0)
      ..quadraticBezierTo(w, 0, w, _cornerRadius)
      ..lineTo(w, _armLength)
      // Kanan bawah
      ..moveTo(w, h - _armLength)
      ..lineTo(w, h - _cornerRadius)
      ..quadraticBezierTo(w, h, w - _cornerRadius, h)
      ..lineTo(w - _armLength, h)
      // Kiri bawah
      ..moveTo(_armLength, h)
      ..lineTo(_cornerRadius, h)
      ..quadraticBezierTo(0, h, 0, h - _cornerRadius)
      ..lineTo(0, h - _armLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
