import '../../data/models/attendance_model.dart'; // Ideally entity
import '../entities/perizinan.dart';
import 'dart:io';

abstract class AttendanceRepository {
  Future<AttendanceModel> checkIn(double lat, double long, {String? reason});
  Future<AttendanceModel> checkInWithPhoto(
    double lat,
    double long,
    dynamic photo, {
    String? reason,
  }); // using dynamic for File/XFile
  Future<AttendanceModel> checkOut(double lat, double long, {String? reason});
  Future<List<AttendanceModel>> getHistory();
  Future<AttendanceRecapModel> getRecap(String month, String year);
  Future<AttendanceRecapModel> getTeamRecap(String month, String year);
  Future<List<AttendanceModel>> getTeamHistory(String month, String year);
  Future<Map<String, dynamic>> getTodayStatus();
  Future<List<Perizinan>> getCorrectionHistory();
  Future<void> submitCorrection({
    required String tanggal,
    required String alasan,
    File? bukti,
  });
}
