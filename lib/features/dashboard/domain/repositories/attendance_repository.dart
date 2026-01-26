import '../../data/models/attendance_model.dart'; // Ideally entity

abstract class AttendanceRepository {
  Future<AttendanceModel> checkIn(double lat, double long);
  Future<AttendanceModel> checkOut(double lat, double long);
  Future<List<AttendanceModel>> getHistory();
  Future<AttendanceRecapModel> getRecap(String month, String year);
  Future<Map<String, dynamic>> getTodayStatus();
}
