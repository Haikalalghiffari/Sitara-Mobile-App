import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/notification_model.dart';

/// Akses notifikasi pada backend SITARA.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
///
/// Backend menyediakan empat operasi: membaca daftar, menandai satu notifikasi
/// sudah dibaca, menandai seluruhnya sudah dibaca, dan menghapus satu
/// notifikasi. Tidak ada penghapusan massal.
class NotificationService {
  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// `GET /notifications`.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.notifications,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `PUT /notifications/{id}/read`, tanpa request body.
  Future<NotificationModel> markAsRead(int id) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.put<dynamic>(
        ApiEndpoints.notificationRead(id),
      );

      return _parseSingle(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `PUT /notifications/read-all`, mengembalikan seluruh notifikasi terbaru.
  Future<List<NotificationModel>> markAllAsRead() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.put<dynamic>(
        ApiEndpoints.notificationsReadAll,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// `DELETE /notifications/{id}`.
  Future<void> delete(int id) async {
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiEndpoints.notification(id),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<NotificationModel> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan daftar notifikasi tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  NotificationModel _parseSingle(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Format balasan notifikasi tidak dikenali.');
    }

    return NotificationModel.fromJson(data);
  }
}
