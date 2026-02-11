import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/perizinan_model.dart';

abstract class LeaveRemoteDataSource {
  Future<String> applyLeave({
    required String tipe, // IZIN / CUTI
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
    File? fileBukti,
  });

  Future<List<PerizinanModel>> getLeaveHistory(); // /api/perizinan/riwayat
  Future<List<PerizinanModel>>
  getSubordinateRequests(); // /api/perizinan/bawahan
  Future<void> approveRequest(int id, String status); // /api/perizinan/approval
  Future<void> cancelLeave(String id); // /api/perizinan/{id}
  Future<void> updateLeave({
    required String id,
    required String tipe,
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
    File? fileBukti,
  });
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final ApiClient apiClient;

  LeaveRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<String> applyLeave({
    required String tipe,
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
    File? fileBukti,
  }) async {
    try {
      dynamic requestData;
      if (fileBukti != null) {
        requestData = FormData.fromMap({
          'tipe': tipe,
          'jenis_izin': jenisIzin,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'keterangan': keterangan,
          'file_bukti': await MultipartFile.fromFile(fileBukti.path),
        });
      } else {
        requestData = {
          'tipe': tipe,
          'jenis_izin': jenisIzin,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'keterangan': keterangan,
        };
      }

      final response = await apiClient.post(
        '/api/perizinan/cuti',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Response might be just data, so default to success message if 'message' is missing
        return response.data is Map
            ? (response.data['message'] ?? 'Berhasil mengajukan izin/cuti')
            : 'Berhasil mengajukan izin/cuti';
      } else {
        throw ServerException(response.statusMessage ?? 'Gagal mengajukan');
      }
    } on DioException catch (e) {
      String msg = e.message ?? 'Gagal mengajukan izin/cuti';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
        } else if (e.response!.data is String) {
          msg = e.response!.data;
        }
      }
      throw ServerException(msg);
    }
  }

  @override
  Future<List<PerizinanModel>> getLeaveHistory() async {
    try {
      final response = await apiClient.get('/api/perizinan/riwayat');
      if (response.statusCode == 200) {
        final List data =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);
        return data
            .map((e) => PerizinanModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw ServerException('Gagal mengambil riwayat');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<PerizinanModel>> getSubordinateRequests() async {
    try {
      final response = await apiClient.get('/api/perizinan/bawahan');
      if (response.statusCode == 200) {
        final List data =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);
        return data
            .map((e) => PerizinanModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw ServerException('Gagal mengambil data bawahan');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> approveRequest(int id, String status) async {
    try {
      await apiClient.post(
        '/api/perizinan/approval',
        data: {'perizinan_id': id, 'status': status}, // DISETUJUI / DITOLAK
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelLeave(String id) async {
    try {
      final response = await apiClient.delete('/api/perizinan/cuti/$id');
      if (response.statusCode != 200) {
        throw ServerException(response.statusMessage ?? 'Gagal membatalkan');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateLeave({
    required String id,
    required String tipe,
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
    File? fileBukti,
  }) async {
    try {
      dynamic requestData;
      if (fileBukti != null) {
        requestData = FormData.fromMap({
          'tipe': tipe,
          'jenis_izin': jenisIzin,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'keterangan': keterangan,
          'file_bukti': await MultipartFile.fromFile(fileBukti.path),
        });
      } else {
        requestData = {
          'tipe': tipe,
          'jenis_izin': jenisIzin,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'keterangan': keterangan,
        };
      }

      final response = await apiClient.put(
        '/api/perizinan/cuti/$id',
        data: requestData,
      );

      if (response.statusCode != 200) {
        throw ServerException(response.statusMessage ?? 'Gagal mengupdate');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengupdate');
    }
  }
}
