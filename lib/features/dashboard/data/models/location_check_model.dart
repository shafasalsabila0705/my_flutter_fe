import '../../domain/entities/location_check.dart';

class LocationCheckModel extends LocationCheck {
  const LocationCheckModel({
    required super.statusLokasi,
    required super.jarakTerdekat,
    required super.namaLokasi,
    required super.alamat,
    required super.latitude,
    required super.longitude,
    required super.radiusMeter,
  });

  factory LocationCheckModel.fromJson(Map<String, dynamic> json) {
    final lokasi = json['lokasi_terdekat'] ?? {};
    return LocationCheckModel(
      statusLokasi: json['status_lokasi'] ?? 'INVALID',
      jarakTerdekat: (json['jarak_terdekat'] as num?)?.toDouble() ?? 0.0,
      namaLokasi: lokasi['nama_lokasi'] ?? '-',
      alamat: lokasi['alamat'] ?? '-',
      latitude: (lokasi['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (lokasi['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeter: (lokasi['radius_meter'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_lokasi': statusLokasi,
      'jarak_terdekat': jarakTerdekat,
      'lokasi_terdekat': {
        'nama_lokasi': namaLokasi,
        'alamat': alamat,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meter': radiusMeter,
      },
    };
  }
}
