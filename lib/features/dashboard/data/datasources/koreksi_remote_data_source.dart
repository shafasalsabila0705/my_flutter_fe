import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/koreksi_model.dart';

abstract class KoreksiRemoteDataSource {
  Future<String> ajukanKoreksi({
    required String tanggalKehadiran,
    required String tipeKoreksi, // TELAT, PULANG_CEPAT, LUAR_RADIUS
    required String alasan,
    File? fileBukti,
  });

  Future<List<KoreksiModel>> getHistory(); // /api/koreksi/riwayat
  Future<List<KoreksiModel>> getSubordinateRequests(); // /api/koreksi/bawahan
  Future<void> approveRequest(int id, String status); // /api/koreksi/approval
}

class KoreksiRemoteDataSourceImpl implements KoreksiRemoteDataSource {
  final ApiClient apiClient;

  KoreksiRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<String> ajukanKoreksi({
    required String tanggalKehadiran,
    required String tipeKoreksi,
    required String alasan,
    File? fileBukti,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'tanggal_kehadiran': tanggalKehadiran,
        'tipe_koreksi': tipeKoreksi,
        'alasan': alasan,
        if (fileBukti != null)
          'file_bukti': await MultipartFile.fromFile(fileBukti.path),
      });

      final response = await apiClient.post(
        '/api/koreksi/ajukan',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Berhasil mengajukan koreksi';
      } else {
        throw ServerException(response.statusMessage ?? 'Gagal mengajukan');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengajukan koreksi');
    }
  }

  @override
  Future<List<KoreksiModel>> getHistory() async {
    try {
      final response = await apiClient.get('/api/koreksi/riwayat');
      if (response.statusCode == 200) {
        final List data =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);
        return data
            .map((e) => KoreksiModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw ServerException('Gagal mengambil riwayat koreksi');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<KoreksiModel>> getSubordinateRequests() async {
    try {
      final response = await apiClient.get('/api/koreksi/bawahan');
      if (response.statusCode == 200) {
        final List data =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);
        return data
            .map((e) => KoreksiModel.fromJson(Map<String, dynamic>.from(e)))
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
        '/api/koreksi/approval',
        data: {'koreksi_id': id, 'status': status},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
