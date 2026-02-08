import 'package:flutter/foundation.dart';
import '../../domain/entities/perizinan.dart';

class PerizinanModel extends Perizinan {
  const PerizinanModel({
    super.id,
    super.tipe,
    super.jenisIzin,
    super.tanggalMulai,
    super.tanggalSelesai,
    super.keterangan,
    super.status,
    super.fileBukti,
    super.name,
    super.nip,
  });

  factory PerizinanModel.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] ??
        json['pegawai'] ??
        json['employee'] ??
        json['asn']; // Added 'asn'
    return PerizinanModel(
      id: (json['id'] ?? json['ID'])?.toString(), // Handle uppercase ID
      tipe: json['tipe']?.toString(),
      jenisIzin: (json['jenis'] ?? json['jenis_izin'])?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalSelesai: json['tanggal_selesai']?.toString(),
      keterangan:
          (json['keterangan'] ??
                  json['alasan'] ??
                  json['deskripsi'] ??
                  json['reason'])
              ?.toString(),
      status: json['status']?.toString(),
      fileBukti: json['file_bukti']?.toString(),
      name:
          (user?['nama'] ??
                  user?['name'] ??
                  user?['nama_lengkap'] ??
                  user?['full_name'] ??
                  json['nama'] ??
                  json['name'] ??
                  json['nama_lengkap'] ??
                  json['full_name'])
              ?.toString(),
      nip: (user?['nip'] ?? json['nip'] ?? json['nip_pegawai'])?.toString(),
    );
  }

  factory PerizinanModel.fromCorrectionJson(Map<String, dynamic> json) {
    // DEBUG LOG
    debugPrint("DEBUG KOREKSI JSON: $json");

    final user =
        json['user'] ?? json['pegawai'] ?? json['employee'] ?? json['asn'];

    // Map Correction Request to Perizinan Structure
    return PerizinanModel(
      id: (json['id'] ?? json['ID'] ?? json['koreksi_id'])
          ?.toString(), // Try koreksi_id too
      tipe: 'KOREKSI', // Custom Type for Frontend Logic
      jenisIzin: (json['tipe_koreksi'] ?? json['tipe'])
          ?.toString(), // 'TELAT', 'PULANG_CEPAT', 'LUAR_RADIUS'
      tanggalMulai: json['tanggal_kehadiran']
          ?.toString(), // Correction usually single day
      tanggalSelesai: json['tanggal_kehadiran']?.toString(),
      keterangan:
          (json['alasan'] ??
                  json['keterangan'] ??
                  json['deskripsi'] ??
                  json['reason'])
              ?.toString(),
      status: json['status']?.toString(),
      fileBukti: json['file_bukti']?.toString(),
      name:
          (user?['nama'] ??
                  user?['name'] ??
                  user?['nama_lengkap'] ??
                  user?['full_name'] ??
                  json['nama'] ??
                  json['name'] ??
                  json['nama_lengkap'] ??
                  json['full_name'])
              ?.toString(),
      nip: (user?['nip'] ?? json['nip'] ?? json['nip_pegawai'])?.toString(),
    );
  }
}
