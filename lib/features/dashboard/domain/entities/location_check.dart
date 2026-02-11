import 'package:equatable/equatable.dart';

class LocationCheck extends Equatable {
  final String statusLokasi;
  final double jarakTerdekat;
  final String namaLokasi;
  final String alamat;
  final double latitude;
  final double longitude;
  final double radiusMeter;

  const LocationCheck({
    required this.statusLokasi,
    required this.jarakTerdekat,
    required this.namaLokasi,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
  });

  @override
  List<Object?> get props => [
    statusLokasi,
    jarakTerdekat,
    namaLokasi,
    alamat,
    latitude,
    longitude,
    radiusMeter,
  ];
}
