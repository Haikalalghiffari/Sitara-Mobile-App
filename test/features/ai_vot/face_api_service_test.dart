import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/features/ai_vot/models/face_registration_result.dart';
import 'package:sitara/features/ai_vot/models/face_status.dart';

void main() {
  group('FaceStatusResponse Model Tests', () {
    test('fromJson parses registered status correctly', () {
      final Map<String, dynamic> json = {
        'is_registered': true,
        'model_version': 'opencv_yunet_sface_v1',
        'registered_at': '2026-08-20T17:00:00.000Z',
      };

      final FaceStatusResponse status = FaceStatusResponse.fromJson(json);

      expect(status.isRegistered, isTrue);
      expect(status.modelVersion, equals('opencv_yunet_sface_v1'));
      expect(status.registeredAt, isNotNull);
    });

    test('fromJson parses unregistered status correctly', () {
      final Map<String, dynamic> json = {
        'is_registered': false,
        'model_version': null,
        'registered_at': null,
      };

      final FaceStatusResponse status = FaceStatusResponse.fromJson(json);

      expect(status.isRegistered, isFalse);
      expect(status.modelVersion, isNull);
      expect(status.registeredAt, isNull);
    });
  });

  group('FaceRegisterResponse Model Tests', () {
    test('fromJson parses successful registration response correctly', () {
      final Map<String, dynamic> json = {
        'status': 'success',
        'message': 'Wajah pasien berhasil didaftarkan.',
        'model_version': 'opencv_yunet_sface_v1',
      };

      final FaceRegisterResponse response = FaceRegisterResponse.fromJson(json);

      expect(response.status, equals('success'));
      expect(response.message, equals('Wajah pasien berhasil didaftarkan.'));
      expect(response.modelVersion, equals('opencv_yunet_sface_v1'));
    });
  });
}
