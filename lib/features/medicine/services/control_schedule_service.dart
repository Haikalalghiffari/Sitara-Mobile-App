import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/control_schedule.dart';

/// Akses jadwal kontrol milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class ControlScheduleService {
  ControlScheduleService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /control-schedules/my`.
  ///
  /// Backend sudah menyaring berdasarkan pemegang token lewat join
  /// `control_schedules → treatments → patients` dan mengurutkannya menurut
  /// tanggal serta jam, jadi hasilnya dipakai apa adanya.
  Future<List<ControlSchedule>> getMySchedules() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myControlSchedules,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<ControlSchedule> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan jadwal kontrol tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ControlSchedule.fromJson)
        .toList();
  }
}
