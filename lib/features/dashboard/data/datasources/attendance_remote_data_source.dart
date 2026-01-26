import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceModel> checkIn(double lat, double long);
  Future<AttendanceModel> checkOut(double lat, double long);
  Future<List<AttendanceModel>> getHistory(); // /api/kehadiran/riwayat
  Future<AttendanceRecapModel> getRecap(
    String month,
    String year,
  ); // /api/kehadiran/rekap
  Future<Map<String, dynamic>>
  getTodayStatus(); // /api/kehadiran/status-hari-ini
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AttendanceModel> checkIn(double lat, double long) async {
    try {
      final response = await apiClient.post(
        '/api/kehadiran/checkin',
        data: {'latitude': lat, 'longitude': long},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Example: { "message": "Check-in berhasil", "status": "HADIR", "waktu": "07:55:00", "jarak": 10.5 }
        return AttendanceModel.fromJson(data);
      } else {
        throw ServerException(response.statusMessage ?? 'Check-in Gagal');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ??
            e.message ??
            'Terjadi kesalahan check-in',
      );
    }
  }

  @override
  Future<AttendanceModel> checkOut(double lat, double long) async {
    try {
      final response = await apiClient.post(
        '/api/kehadiran/checkout',
        data: {'latitude': lat, 'longitude': long},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Assuming consistent response or just message
        return AttendanceModel(
          status: 'PULANG',
          checkInTime: 'Now',
        ); // Helper model since response might be empty
      } else {
        throw ServerException(response.statusMessage ?? 'Check-out Gagal');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ??
            e.message ??
            'Terjadi kesalahan check-out',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getHistory() async {
    try {
      final response = await apiClient.get('/api/kehadiran/riwayat');

      if (response.statusCode == 200) {
        final List list =
            response.data['data'] ??
            []; // Adjust based on actual response wrapper
        return list.map((e) => AttendanceModel.fromJson(e)).toList();
      } else {
        throw ServerException('Gagal mengambil riwayat');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil riwayat');
    }
  }

  @override
  Future<AttendanceRecapModel> getRecap(String month, String year) async {
    try {
      final response = await apiClient.get(
        '/api/kehadiran/rekap',
        queryParameters: {'bulan': month, 'tahun': year},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return AttendanceRecapModel.fromJson(data);
      } else {
        throw ServerException('Gagal mengambil rekap');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil rekap');
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      final response = await apiClient.get('/api/kehadiran/status-hari-ini');
      if (response.statusCode == 200) {
        return response.data ?? {};
      } else {
        throw ServerException('Gagal mengambil status hari ini');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil status');
    }
  }
}
