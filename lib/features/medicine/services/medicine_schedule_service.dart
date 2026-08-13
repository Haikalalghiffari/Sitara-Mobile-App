import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/my_medicine_schedule.dart';

/// Akses jadwal minum obat milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class MedicineScheduleService {
  MedicineScheduleService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /medicine-schedules/my`.
  ///
  /// Backend sudah menyaring berdasarkan pemegang token lewat join
  /// `medicine_schedules → treatments → patients`, jadi hasilnya dipakai apa
  /// adanya tanpa penyaringan ulang di sisi aplikasi.
  Future<List<MyMedicineSchedule>> getMySchedules() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myMedicineSchedules,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<MyMedicineSchedule> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan jadwal obat tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(MyMedicineSchedule.fromJson)
        .toList();
  }
}
