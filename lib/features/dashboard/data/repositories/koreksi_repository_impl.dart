import 'dart:io';
import '../../domain/repositories/koreksi_repository.dart';
import '../datasources/koreksi_remote_data_source.dart';
import '../models/koreksi_model.dart';

class KoreksiRepositoryImpl implements KoreksiRepository {
  final KoreksiRemoteDataSource remoteDataSource;

  KoreksiRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> ajukanKoreksi({
    required String tanggalKehadiran,
    required String tipeKoreksi,
    required String alasan,
    File? fileBukti,
  }) async {
    return await remoteDataSource.ajukanKoreksi(
      tanggalKehadiran: tanggalKehadiran,
      tipeKoreksi: tipeKoreksi,
      alasan: alasan,
      fileBukti: fileBukti,
    );
  }

  @override
  Future<List<KoreksiModel>> getHistory() async {
    return await remoteDataSource.getHistory();
  }

  @override
  Future<List<KoreksiModel>> getSubordinateRequests() async {
    return await remoteDataSource.getSubordinateRequests();
  }

  @override
  Future<void> approveRequest(int id, String status) async {
    await remoteDataSource.approveRequest(id, status);
  }
}
