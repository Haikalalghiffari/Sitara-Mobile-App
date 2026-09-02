import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/daily_medication.dart';
import '../models/vot_complete_response.dart';
import '../models/vot_face_verify_result.dart';
import '../models/vot_medicine_detect_result.dart';
import '../models/vot_start_response.dart';
import '../utils/vot_flow.dart';

/// Akses API VOT. Memakai [ApiClient] yang sama; Bearer dipasang interceptor.
class VotService {
  VotService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  static const Duration _uploadTimeout = Duration(seconds: 45);

  Future<List<DailyMedication>> listToday() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.medicationsToday,
      );

      if (response.data is! List) {
        throw const ApiException(
          'Format balasan jadwal obat hari ini tidak dikenali.',
        );
      }

      final List<DailyMedication> items = <DailyMedication>[];
      for (final dynamic raw in response.data as List<dynamic>) {
        if (raw is! Map) continue;
        items.add(
          DailyMedication.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
      return items;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException(
        'Format balasan jadwal obat hari ini tidak dikenali.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<VotStartResponse> start({required int medicineScheduleId}) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.votStart,
        data: <String, int>{
          'medicine_schedule_id': medicineScheduleId,
        },
      );

      return _parseStart(response.data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Format balasan mulai VOT tidak dikenali.');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `POST /vot/face-verify`. Jangan kirim `medicine_schedule_id`.
  Future<VotFaceVerifyResult> verifyFace({
    required int dailyMedicationId,
    required String imagePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'daily_medication_id': dailyMedicationId.toString(),
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: _fileName(imagePath),
          contentType: DioMediaType.parse(_imageContentType(imagePath)),
        ),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.votFaceVerify,
        data: formData,
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );

      return _parseFace(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<VotMedicineDetectResult> detectMedicine({
    required int dailyMedicationId,
    required String imagePath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'daily_medication_id': dailyMedicationId.toString(),
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: _fileName(imagePath),
          contentType: DioMediaType.parse(_imageContentType(imagePath)),
        ),
      });

      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.votMedicineDetect,
        data: formData,
        options: Options(
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
        ),
      );

      return _parseMedicine(response.data);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<DailyMedication> getSession(int dailyMedicationId) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.votSession(dailyMedicationId),
      );

      if (response.data is! Map) {
        throw const ApiException('Format balasan sesi VOT tidak dikenali.');
      }

      return DailyMedication.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Format balasan sesi VOT tidak dikenali.');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `POST /vot/{daily_medication_id}/video`. Upload automatic video evidence.
  Future<void> uploadVideo({
    required int dailyMedicationId,
    required String videoPath,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'video': await MultipartFile.fromFile(
          videoPath,
          filename: _fileName(videoPath),
          contentType: DioMediaType.parse(_videoContentType(videoPath)),
        ),
      });

      await _apiClient.dio.post<dynamic>(
        ApiEndpoints.votVideo(dailyMedicationId),
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `POST /vot/complete`. Sukses UI hanya jika [VotCompleteResponse.isFinalSuccess].
  Future<VotCompleteResponse> complete({
    required int dailyMedicationId,
    bool drinkingVerified = true,
    String? maxDrinkingStage,
    String? failureReason,
  }) async {
    final Map<String, Object>? body = VotFlow.completeRequestBody(
      dailyMedicationId,
      drinkingVerified: drinkingVerified,
      maxDrinkingStage: maxDrinkingStage,
      failureReason: failureReason,
    );
    if (body == null) {
      throw const ApiException(
        'ID sesi VOT tidak tersedia. Tidak dapat menyelesaikan verifikasi.',
      );
    }

    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.votComplete,
        data: body,
      );

      return _parseComplete(response.data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException(
        'Format balasan penyelesaian VOT tidak dikenali.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  VotStartResponse _parseStart(dynamic data) {
    if (data is! Map) {
      throw const ApiException('Format balasan mulai VOT tidak dikenali.');
    }
    return VotStartResponse.fromJson(Map<String, dynamic>.from(data));
  }

  VotFaceVerifyResult _parseFace(dynamic data) {
    if (data is! Map) {
      throw const ApiException(
        'Format balasan verifikasi wajah tidak dikenali.',
      );
    }
    return VotFaceVerifyResult.fromJson(Map<String, dynamic>.from(data));
  }

  VotMedicineDetectResult _parseMedicine(dynamic data) {
    if (data is! Map) {
      throw const ApiException(
        'Format balasan deteksi obat tidak dikenali.',
      );
    }
    return VotMedicineDetectResult.fromJson(Map<String, dynamic>.from(data));
  }

  VotCompleteResponse _parseComplete(dynamic data) {
    if (data is! Map) {
      throw const ApiException(
        'Format balasan penyelesaian VOT tidak dikenali.',
      );
    }
    return VotCompleteResponse.fromJson(Map<String, dynamic>.from(data));
  }

  static String _fileName(String path) {
    final String name = path.split(RegExp(r'[\\/]')).last;
    return name.isEmpty ? 'capture.jpg' : name;
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

  static String _videoContentType(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.3gp')) return 'video/3gpp';
    return 'video/mp4';
  }
}