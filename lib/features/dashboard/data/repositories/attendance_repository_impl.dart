import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/perizinan.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/attendance_model.dart';
import 'dart:io';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AttendanceModel> checkIn(
    double lat,
    double long, {
    String? reason,
  }) async {
    try {
      return await remoteDataSource.checkIn(lat, long, reason: reason);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AttendanceModel> checkInWithPhoto(
    double lat,
    double long,
    dynamic photo, {
    String? reason,
  }) async {
    try {
      return await remoteDataSource.checkInWithPhoto(
        lat,
        long,
        photo,
        reason: reason,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AttendanceRecapModel> getTeamRecap(String month, String year) async {
    try {
      return await remoteDataSource.getTeamRecap(month, year);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AttendanceModel>> getTeamHistory(
    String month,
    String year,
  ) async {
    try {
      return await remoteDataSource.getTeamHistory(month, year);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AttendanceModel> checkOut(
    double lat,
    double long, {
    String? reason,
  }) async {
    try {
      return await remoteDataSource.checkOut(lat, long, reason: reason);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AttendanceModel>> getHistory() async {
    try {
      return await remoteDataSource.getHistory();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AttendanceRecapModel> getRecap(String month, String year) async {
    try {
      return await remoteDataSource.getRecap(month, year);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      return await remoteDataSource.getTodayStatus();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Perizinan>> getCorrectionHistory() async {
    try {
      return await remoteDataSource.getCorrectionHistory();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> submitCorrection({
    required String tanggal,
    required String alasan,
    File? bukti,
  }) async {
    try {
      await remoteDataSource.submitCorrection(
        tanggal: tanggal,
        alasan: alasan,
        bukti: bukti,
      );
    } catch (e) {
      rethrow;
    }
  }
}
