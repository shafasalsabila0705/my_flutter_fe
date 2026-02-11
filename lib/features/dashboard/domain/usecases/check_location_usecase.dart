import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/attendance_repository.dart';
import '../entities/location_check.dart';
import 'dart:async';

class CheckLocationUseCase extends UseCase<LocationCheck, CheckLocationParams> {
  final AttendanceRepository _repository;

  CheckLocationUseCase(this._repository);

  @override
  Future<Stream<LocationCheck?>> buildUseCaseStream(
    CheckLocationParams? params,
  ) async {
    final controller = StreamController<LocationCheck?>();
    try {
      if (params == null) {
        throw Exception("Params required for CheckLocationUseCase");
      }
      final result = await _repository.checkLocation(params.lat, params.long);
      controller.add(result);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}

class CheckLocationParams {
  final double lat;
  final double long;
  CheckLocationParams({required this.lat, required this.long});
}
