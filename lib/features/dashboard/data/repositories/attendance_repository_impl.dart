import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AttendanceModel> checkIn(double lat, double long) async {
    try {
      return await remoteDataSource.checkIn(lat, long);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AttendanceModel> checkOut(double lat, double long) async {
    try {
      return await remoteDataSource.checkOut(lat, long);
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
}
