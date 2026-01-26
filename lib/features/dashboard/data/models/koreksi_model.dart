import '../../domain/entities/koreksi.dart';

class KoreksiModel extends Koreksi {
  const KoreksiModel({
    super.id,
    super.tanggalKehadiran,
    super.tipeKoreksi,
    super.alasan,
    super.fileBukti,
    super.status,
    super.name,
    super.nip,
  });

  factory KoreksiModel.fromJson(Map<String, dynamic> json) {
    return KoreksiModel(
      id: json['id']?.toString(),
      tanggalKehadiran: json['tanggal_kehadiran']?.toString(),
      tipeKoreksi: json['tipe_koreksi']?.toString(),
      alasan: json['alasan']?.toString(),
      fileBukti: json['file_bukti']?.toString(),
      status: json['status']?.toString(),
      name: (json['nama'] ?? json['name'])?.toString(),
      nip: json['nip']?.toString(),
    );
  }
}
