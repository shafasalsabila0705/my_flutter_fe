import 'package:equatable/equatable.dart';

class Perizinan extends Equatable {
  final String? id;
  final String? tipe;
  final String? jenisIzin;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final String? keterangan;
  final String? status;
  final String? fileBukti;
  final String? name;
  final String? nip;

  const Perizinan({
    this.id,
    this.tipe,
    this.jenisIzin,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.keterangan,
    this.status,
    this.fileBukti,
    this.name,
    this.nip,
  });

  @override
  List<Object?> get props => [
    id,
    tipe,
    jenisIzin,
    tanggalMulai,
    tanggalSelesai,
    keterangan,
    status,
    fileBukti,
    name,
    nip,
  ];
}
