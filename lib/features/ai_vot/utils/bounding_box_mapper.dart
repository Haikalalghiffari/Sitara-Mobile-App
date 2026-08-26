import 'dart:math' as math;
import 'dart:ui';

import '../models/vot_medicine_detect_result.dart';

/// Memetakan box pixel gambar (OpenCV/YOLO) ke widget preview `BoxFit.cover`.
///
/// Backend: `x,y,width,height` pada gambar hasil `cv2.imdecode`, origin kiri atas.
/// Preview AI-VOT memakai `FittedBox(fit: BoxFit.cover)` + kamera depan yang
/// di-mirror oleh `CameraPreview`.
class BoundingBoxMapper {
  const BoundingBoxMapper._();

  static Rect? toPreview({
    required MedicineBoundingBox box,
    required Size imageSize,
    required Size previewSize,
    required bool mirrorHorizontally,
  }) {
    if (imageSize.width <= 0 ||
        imageSize.height <= 0 ||
        previewSize.width <= 0 ||
        previewSize.height <= 0) {
      return null;
    }
    if (box.width <= 0 || box.height <= 0) return null;

    final double scale = math.max(
      previewSize.width / imageSize.width,
      previewSize.height / imageSize.height,
    );
    final double scaledWidth = imageSize.width * scale;
    final double scaledHeight = imageSize.height * scale;
    final double dx = (previewSize.width - scaledWidth) / 2;
    final double dy = (previewSize.height - scaledHeight) / 2;

    double left = box.x * scale + dx;
    final double top = box.y * scale + dy;
    final double width = box.width * scale;
    final double height = box.height * scale;

    if (mirrorHorizontally) {
      left = previewSize.width - left - width;
    }

    return Rect.fromLTWH(left, top, width, height);
  }
}
