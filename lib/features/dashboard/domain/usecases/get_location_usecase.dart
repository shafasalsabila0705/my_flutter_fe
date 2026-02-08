import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class GetLocationUseCase extends UseCase<LocationResult, void> {
  final LocationService _locationService;

  GetLocationUseCase(this._locationService);

  @override
  Future<Stream<LocationResult>> buildUseCaseStream(void params) async {
    final controller = StreamController<LocationResult>();
    try {
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        controller.addError("Layanan lokasi tidak aktif atau izin ditolak.");
        controller.close();
        return controller.stream;
      }

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        LocationService.officeLat,
        LocationService.officeLong,
      );
      final isWithin = distance <= LocationService.radiusInMeters;

      controller.add(
        LocationResult(
          position: position,
          address: address,
          isWithinRadius: isWithin,
        ),
      );
      controller.close();
    } catch (e) {
      controller.addError(e.toString());
      controller.close();
    }
    return controller.stream;
  }
}

class LocationResult {
  final Position position;
  final String address;
  final bool isWithinRadius;

  LocationResult({
    required this.position,
    required this.address,
    required this.isWithinRadius,
  });
}
