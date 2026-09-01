import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

/// Overlay bounding box deteksi obat, sudah dalam koordinat preview.
class MedicineBoundingBoxOverlay extends StatelessWidget {
  const MedicineBoundingBoxOverlay({
    super.key,
    required this.rect,
    this.label,
  });

  final Rect rect;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryLight, width: 2),
          ),
          child: label == null || label!.isEmpty
              ? null
              : Align(
                  alignment: Alignment.topLeft,
                  child: ColoredBox(
                    color: AppColors.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        label!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
