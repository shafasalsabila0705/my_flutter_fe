import 'dart:io';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/perizinan.dart';
import '../../domain/repositories/leave_repository.dart';
import '../../data/datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;

  LeaveRepositoryImpl({required this.remoteDataSource});

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
      return await remoteDataSource.applyLeave(
        tipe: tipe,
        jenisIzin: jenisIzin,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        keterangan: keterangan,
        fileBukti: fileBukti,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Perizinan>> getLeaveHistory() async {
    try {
      return await remoteDataSource.getLeaveHistory();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Perizinan>> getSubordinateRequests() async {
    try {
      return await remoteDataSource.getSubordinateRequests();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> approveRequest(int id, String status) async {
    try {
      await remoteDataSource.approveRequest(id, status);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
