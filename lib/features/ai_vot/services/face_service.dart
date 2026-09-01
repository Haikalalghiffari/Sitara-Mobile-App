import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/face_register_result.dart';
import '../models/face_status.dart';
import '../models/face_verify_result.dart';

/// Akses API Face Recognition milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang interceptor.
class FaceService {
  FaceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const Duration _uploadTimeout = Duration(seconds: 45);

  /// Mengambil `GET /face/status`.
  Future<FaceStatus> getStatus() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.faceStatus,
      );

      return _parseStatus(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengirim `POST /face/register` sebagai multipart field `image`.
  ///
  /// Backend mengekstrak embedding di server. Aplikasi tidak menyimpan
  /// embedding maupun foto secara permanen.
  Future<FaceRegisterResult> registerFace({
    required String imagePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: _fileName(imagePath),
          contentType: DioMediaType.parse(_imageContentType(imagePath)),
        ),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.faceRegister,
        data: formData,
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );

      return _parseRegister(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengambil `id` jadwal milik pemegang token dari `GET /medicine-schedules/my`.
  ///
  /// `POST /face/verify` mewajibkan form `medicine_schedule_id` (PK
  /// `medicine_schedules.id`) untuk cek kepemilikan dan audit. Endpoint
  /// pasien `/medicine-schedules/my` secara schema OpenAPI tidak
  /// mendeklarasikan `id`; field itu hanya dipakai bila server benar-benar
  /// mengirimkannya.
  Future<int> resolveMedicineScheduleId() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myMedicineSchedules,
      );

      return _pickMedicineScheduleId(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengirim `POST /face/verify` dengan field `image` dan
  /// `medicine_schedule_id`.
  Future<FaceVerifyResult> verifyFace({
    required String imagePath,
    required int medicineScheduleId,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: _fileName(imagePath),
          contentType: DioMediaType.parse(_imageContentType(imagePath)),
        ),
        'medicine_schedule_id': medicineScheduleId.toString(),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.faceVerify,
        data: formData,
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );

      return _parseVerify(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  FaceStatus _parseStatus(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Format balasan status wajah tidak dikenali.',
      );
    }

    return FaceStatus.fromJson(data);
  }

  FaceRegisterResult _parseRegister(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Format balasan pendaftaran wajah tidak dikenali.',
      );
    }

    final FaceRegisterResult result = FaceRegisterResult.fromJson(data);
    if (!result.isSuccess) {
      throw const ApiException(
        'Pendaftaran wajah tidak berhasil. Silakan coba lagi.',
      );
    }

    return result;
  }

  FaceVerifyResult _parseVerify(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Format balasan verifikasi wajah tidak dikenali.',
      );
    }

    return FaceVerifyResult.fromJson(data);
  }

  static int _pickMedicineScheduleId(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan jadwal obat tidak dikenali.',
      );
    }

    final List<Map<String, dynamic>> items = data
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
        .toList();

    if (items.isEmpty) {
      throw const ApiException(
        'Jadwal minum obat belum tersedia. Hubungi petugas kesehatan.',
      );
    }

    final List<_ScheduleCandidate> candidates = <_ScheduleCandidate>[];
    for (final Map<String, dynamic> item in items) {
      final int? id = (item['id'] as num?)?.toInt();
      if (id == null || id <= 0) continue;
      candidates.add(
        _ScheduleCandidate(
          id: id,
          drinkMinutes: _drinkMinutesOfDay(item['drink_time']?.toString()),
        ),
      );
    }

    if (candidates.isEmpty) {
      throw const ApiException(
        'Verifikasi wajah memerlukan ID jadwal minum obat, tetapi '
        'GET /medicine-schedules/my tidak mengirim field id.',
      );
    }

    final List<_ScheduleCandidate> timed = candidates
        .where((_ScheduleCandidate item) => item.drinkMinutes != null)
        .toList()
      ..sort(
        (_ScheduleCandidate a, _ScheduleCandidate b) =>
            a.drinkMinutes!.compareTo(b.drinkMinutes!),
      );

    if (timed.isEmpty) return candidates.first.id;

    final DateTime now = DateTime.now();
    final int currentMinutes = now.hour * 60 + now.minute;
    for (final _ScheduleCandidate item in timed) {
      if (item.drinkMinutes! >= currentMinutes) return item.id;
    }

    return timed.first.id;
  }

  static int? _drinkMinutesOfDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final List<String> parts = raw.split(':');
    if (parts.length < 2) return null;

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String _fileName(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    return name.isEmpty ? 'face.jpg' : name;
  }

  static String _imageContentType(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }
}

class _ScheduleCandidate {
  const _ScheduleCandidate({
    required this.id,
    required this.drinkMinutes,
  });

  final int id;
  final int? drinkMinutes;
}
