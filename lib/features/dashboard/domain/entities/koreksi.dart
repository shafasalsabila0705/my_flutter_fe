import 'package:equatable/equatable.dart';

class Koreksi extends Equatable {
  final String? id;
  final String? tanggalKehadiran;
  final String? tipeKoreksi;
  final String? alasan;
  final String? fileBukti;
  final String? status;
  final String? name;
  final String? nip;

  const Koreksi({
    this.id,
    this.tanggalKehadiran,
    this.tipeKoreksi,
    this.alasan,
    this.fileBukti,
    this.status,
    this.name,
    this.nip,
  });

  @override
  List<Object?> get props => [
    id,
    tanggalKehadiran,
    tipeKoreksi,
    alasan,
    fileBukti,
    status,
    name,
    nip,
  ];
}
