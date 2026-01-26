import 'dart:io';
import '../entities/perizinan.dart';

abstract class LeaveRepository {
  Future<String> applyLeave({
    required String tipe,
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String keterangan,
    File? fileBukti,
  });
  Future<List<Perizinan>> getLeaveHistory();
  Future<List<Perizinan>> getSubordinateRequests();
  Future<void> approveRequest(int id, String status);
}
