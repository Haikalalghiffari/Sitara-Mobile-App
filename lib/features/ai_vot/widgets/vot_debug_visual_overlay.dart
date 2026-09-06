import 'package:flutter/material.dart';
import '../models/vot_debug_state.dart';

/// Visual overlay yang menggambar titik mulut, fingertip,
/// dan garis jarak di atas camera preview.
///
/// Koordinat dari MediaPipe adalah normalized [0..1].
/// CameraPreview menggunakan FittedBox(fit: BoxFit.cover),
/// sehingga kita perlu transformasi yang tepat.
class VotDebugVisualOverlay extends StatelessWidget {
  const VotDebugVisualOverlay({
    super.key,
    required this.notifier,
    required this.previewSize,
    required this.cameraPreviewAspect,
  });

  final VotDebugNotifier notifier;

  /// Ukuran widget preview (constraints dari LayoutBuilder).
  final Size previewSize;

  /// Aspect ratio dari camera preview (width / height dalam portrait).
  /// Contoh: 480/640 = 0.75.
  final double cameraPreviewAspect;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VotDebugState>(
      valueListenable: notifier,
      builder: (BuildContext context, VotDebugState state, _) {
        return CustomPaint(
          size: previewSize,
          painter: _VotDebugPainter(
            state: state,
            containerSize: previewSize,
            cameraAspect: cameraPreviewAspect,
          ),
        );
      },
    );
  }
}

class _VotDebugPainter extends CustomPainter {
  _VotDebugPainter({
    required this.state,
    required this.containerSize,
    required this.cameraAspect,
  });

  final VotDebugState state;
  final Size containerSize;
  final double cameraAspect;

  /// Transform normalized coordinates [0..1] ke pixel pada preview widget.
  ///
  /// Camera preview menggunakan FittedBox(fit: BoxFit.cover).
  /// Ini berarti:
  /// 1. Camera image di-scale supaya menutupi seluruh container.
  /// 2. Bagian yang overflow di-crop.
  ///
  /// Misal container = 360x480 (aspect 0.75), camera = 480x640 (aspect 0.75):
  /// Tidak ada crop, langsung scale 1:1.
  ///
  /// Misal container = 360x500 (aspect 0.72), camera aspect = 0.75:
  /// Camera harus di-scale hingga tinggi = 500, width = 500 * 0.75 = 375.
  /// Overflow horizontal = (375 - 360) / 2 = 7.5px.
  /// Jadi x offset = -7.5.
  Offset _toPixel(double normalizedX, double normalizedY) {
    final double containerW = containerSize.width;
    final double containerH = containerSize.height;
    final double containerAspect = containerW / containerH;

    double scaledW, scaledH;
    if (cameraAspect > containerAspect) {
      // Camera lebih lebar (dalam portrait context) → crop horizontal.
      scaledH = containerH;
      scaledW = containerH * cameraAspect;
    } else {
      // Camera lebih tinggi → crop vertical.
      scaledW = containerW;
      scaledH = containerW / cameraAspect;
    }

    // Normalized coordinate * scaled size = pixel position in scaled image.
    // Offset karena FittedBox centering:
    final double offsetX = (scaledW - containerW) / 2;
    final double offsetY = (scaledH - containerH) / 2;

    final double px = normalizedX * scaledW - offsetX;
    final double py = normalizedY * scaledH - offsetY;

    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── Mouth ──
    if (state.mouthX != null && state.mouthY != null) {
      final Offset mouth = _toPixel(state.mouthX!, state.mouthY!);
      _drawPoint(canvas, mouth, Colors.cyanAccent, 'MOUTH', 8);
    }

    // ── Fingertips ──
    final List<_TipInfo> tips = <_TipInfo>[
      _TipInfo('T4', state.thumbTipX, state.thumbTipY, 4),
      _TipInfo('I8', state.indexTipX, state.indexTipY, 8),
      _TipInfo('M12', state.middleTipX, state.middleTipY, 12),
    ];

    for (final _TipInfo tip in tips) {
      if (tip.x != null && tip.y != null) {
        final Offset p = _toPixel(tip.x!, tip.y!);
        final bool isClosest = tip.index == state.closestTipIndex;
        _drawPoint(canvas, p,
            isClosest ? Colors.greenAccent : Colors.orangeAccent,
            tip.label, isClosest ? 7 : 5);
      }
    }

    // ── Line from closest tip to mouth ──
    if (state.mouthX != null &&
        state.mouthY != null &&
        state.distance != null) {
      final _TipInfo? closest = _getClosestTip(tips);
      if (closest != null && closest.x != null && closest.y != null) {
        final Offset mouth = _toPixel(state.mouthX!, state.mouthY!);
        final Offset hand = _toPixel(closest.x!, closest.y!);

        final Paint linePaint = Paint()
          ..color = _lineColor(state.distance!, state.nearThreshold)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawLine(mouth, hand, linePaint);

        // Distance label at midpoint.
        final Offset mid = Offset(
          (mouth.dx + hand.dx) / 2,
          (mouth.dy + hand.dy) / 2,
        );

        _drawDistanceLabel(canvas, mid, state.distance!);
      }
    }
  }

  _TipInfo? _getClosestTip(List<_TipInfo> tips) {
    for (final _TipInfo tip in tips) {
      if (tip.index == state.closestTipIndex &&
          tip.x != null &&
          tip.y != null) {
        return tip;
      }
    }
    // Fallback: any visible tip.
    for (final _TipInfo tip in tips) {
      if (tip.x != null && tip.y != null) return tip;
    }
    return null;
  }

  void _drawPoint(
      Canvas canvas, Offset center, Color color, String label, double radius) {
    // Outer ring.
    final Paint ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner dot.
    final Paint dotPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, dotPaint);

    // Label.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const <Shadow>[
            Shadow(blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, center + Offset(-tp.width / 2, radius + 2));
  }

  void _drawDistanceLabel(Canvas canvas, Offset position, double distance) {
    final Color color = _lineColor(distance, state.nearThreshold);
    final String text = distance.toStringAsFixed(3);

    // Background.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const <Shadow>[
            Shadow(blurRadius: 3, color: Colors.black),
            Shadow(blurRadius: 6, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Rect bg = Rect.fromCenter(
      center: position,
      width: tp.width + 8,
      height: tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bg, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    tp.paint(canvas, Offset(bg.left + 4, bg.top + 2));
  }

  Color _lineColor(double distance, double nearThreshold) {
    if (distance <= nearThreshold) return Colors.green;
    if (distance <= 0.34) return Colors.yellow;
    return Colors.red;
  }

  @override
  bool shouldRepaint(_VotDebugPainter oldDelegate) => true;
}

class _TipInfo {
  const _TipInfo(this.label, this.x, this.y, this.index);
  final String label;
  final double? x;
  final double? y;
  final int index;
}
