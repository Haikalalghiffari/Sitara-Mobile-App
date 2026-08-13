import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/complaint.dart';

/// Akses keluhan milik pasien yang sedang login.
///
/// Memakai [ApiClient] yang sama dengan fitur lain, sehingga header
/// `Authorization: Bearer <token>` sudah dipasang otomatis oleh interceptor.
class ComplaintService {
  ComplaintService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  /// Mengambil `GET /complaints/my`.
  ///
  /// Backend sudah menyaring berdasarkan pemegang token lewat join
  /// `complaints → treatments → patients` dan mengurutkannya dari yang
  /// terbaru, jadi hasilnya dipakai apa adanya.
  Future<List<Complaint>> getMyComplaints() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        ApiEndpoints.myComplaints,
      );

      return _parseList(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  /// Mengirim `POST /complaints` dengan body `ComplaintCreate`.
  ///
  /// Backend menolak dengan 403 bila `treatment_id` bukan milik pasien yang
  /// sedang login, jadi id tersebut wajib berasal dari `GET /treatments/my`.
  Future<Complaint> createComplaint({
    required int treatmentId,
    required String category,
    required String description,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.dio.post<dynamic>(
        ApiEndpoints.complaints,
        data: <String, dynamic>{
          'treatment_id': treatmentId,
          'category': category,
          'description': description,
        },
      );

      return _parseSingle(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  List<Complaint> _parseList(dynamic data) {
    if (data is! List) {
      throw const ApiException(
        'Format balasan riwayat keluhan tidak dikenali.',
      );
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Complaint.fromJson)
        .toList();
  }

  Complaint _parseSingle(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Format balasan keluhan tidak dikenali.',
      );
    }

    return Complaint.fromJson(data);
  }
}
