import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/vot_medicine_detect_result.dart';
import 'package:sitara/features/ai_vot/utils/bounding_box_mapper.dart';

void main() {
  test('maps image pixels through BoxFit.cover without magic offsets', () {
    const MedicineBoundingBox box = MedicineBoundingBox(
      x: 100,
      y: 50,
      width: 200,
      height: 100,
    );
    final Rect? mapped = BoundingBoxMapper.toPreview(
      box: box,
      imageSize: const Size(400, 200),
      previewSize: const Size(200, 200),
      mirrorHorizontally: false,
    );

    expect(mapped, isNotNull);
    // cover scale = max(200/400, 200/200) = 1.0, dx = (200-400)/2 = -100
    expect(mapped!.left, 0);
    expect(mapped.top, 50);
    expect(mapped.width, 200);
    expect(mapped.height, 100);
  });

  test('mirrors X for front camera preview', () {
    const MedicineBoundingBox box = MedicineBoundingBox(
      x: 0,
      y: 0,
      width: 50,
      height: 50,
    );
    final Rect? mapped = BoundingBoxMapper.toPreview(
      box: box,
      imageSize: const Size(100, 100),
      previewSize: const Size(100, 100),
      mirrorHorizontally: true,
    );
    expect(mapped!.left, 50);
    expect(mapped.width, 50);
  });
}
