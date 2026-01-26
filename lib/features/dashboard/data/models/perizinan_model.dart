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
    return PerizinanModel(
      id: json['id']?.toString(),
      tipe: json['tipe']?.toString(),
      jenisIzin: (json['jenis'] ?? json['jenis_izin'])?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalSelesai: json['tanggal_selesai']?.toString(),
      keterangan: json['keterangan']?.toString(),
      status: json['status']?.toString(),
      fileBukti: json['file_bukti']?.toString(),
      name:
          (json['user']?['nama'] ??
                  json['user']?['name'] ??
                  json['nama'] ??
                  json['name'])
              ?.toString(),
      nip: (json['user']?['nip'] ?? json['nip'])?.toString(),
    );
  }
}
