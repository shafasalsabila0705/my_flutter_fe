import 'dart:io';
import '../../data/models/koreksi_model.dart';

abstract class KoreksiRepository {
  Future<String> ajukanKoreksi({
    required String tanggalKehadiran,
    required String tipeKoreksi,
    required String alasan,
    File? fileBukti,
  });

  Future<List<KoreksiModel>> getHistory();
  Future<List<KoreksiModel>> getSubordinateRequests();
  Future<void> approveRequest(int id, String status);
}
