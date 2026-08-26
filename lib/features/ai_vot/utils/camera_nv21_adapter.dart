import 'package:camera/camera.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

/// Konversi `CameraImage` Android ke NV21 untuk Face Landmarker.
class CameraNv21Adapter {
  const CameraNv21Adapter._();

  static FaceMeshNv21Image? toNv21(CameraImage image) {
    final List<Plane> planes = image.planes;
    if (planes.isEmpty) return null;
    if ((image.width & 1) != 0 || (image.height & 1) != 0) return null;

    if (planes.length == 1) {
      final Plane plane = planes.first;
      return FaceMeshNv21Image.tryFromSinglePlane(
        bytes: plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
      );
    }

    if (planes.length == 2) {
      return FaceMeshNv21Image.tryFromYAndInterleavedVuPlanes(
        width: image.width,
        height: image.height,
        yPlane: _plane(planes[0]),
        vuPlane: _plane(planes[1]),
      );
    }

    return FaceMeshNv21Image.tryFromYuv420Planes(
      width: image.width,
      height: image.height,
      yPlane: _plane(planes[0]),
      uPlane: _plane(planes[1]),
      vPlane: _plane(planes[2]),
    );
  }

  static FaceMeshImagePlane _plane(Plane plane) {
    return FaceMeshImagePlane(
      bytes: plane.bytes,
      bytesPerRow: plane.bytesPerRow,
      bytesPerPixel: plane.bytesPerPixel,
    );
  }
}
