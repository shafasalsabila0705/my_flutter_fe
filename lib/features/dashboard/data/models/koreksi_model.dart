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
    // Check for nested user object
    final user =
        json['user'] ?? json['pegawai'] ?? json['employee'] ?? json['asn'];

    // Robust ID parsing
    final parsedId = json['id'] ?? json['ID'] ?? json['koreksi_id'];

    return KoreksiModel(
      id: parsedId?.toString(),
      tanggalKehadiran: json['tanggal_kehadiran']?.toString(),
      tipeKoreksi: json['tipe_koreksi']?.toString(),
      alasan: json['alasan']?.toString(),
      fileBukti:
          (json['file_bukti'] ??
                  json['path_file'] ??
                  json['bukti'] ??
                  json['lampiran'] ??
                  json['attachment'] ??
                  json['foto'] ??
                  json['image'])
              ?.toString(),
      status: json['status']?.toString(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal_kehadiran': tanggalKehadiran,
      'tipe_koreksi': tipeKoreksi,
      'alasan': alasan,
      'file_bukti': fileBukti,
      'status': status,
      'name': name,
      'nip': nip,
    };
  }
}
