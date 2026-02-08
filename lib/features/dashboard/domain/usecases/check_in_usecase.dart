import 'dart:async';
import 'dart:io';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';

class CheckInUseCase extends UseCase<AttendanceModel, CheckInParams> {
  final AttendanceRepository _repository;

  CheckInUseCase(this._repository);

  @override
  Future<Stream<AttendanceModel>> buildUseCaseStream(
    CheckInParams? params,
  ) async {
    final controller = StreamController<AttendanceModel>();
    try {
      if (params == null) throw Exception("Params null");

      AttendanceModel result;
      if (params.photo != null) {
        result = await _repository.checkInWithPhoto(
          params.lat,
          params.long,
          params.photo!,
          reason: params.reason,
        );
      } else {
        result = await _repository.checkIn(
          params.lat,
          params.long,
          reason: params.reason,
        );
      }
      controller.add(result);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}

class CheckInParams {
  final double lat;
  final double long;
  final File? photo;
  final String? reason;

  CheckInParams({
    required this.lat,
    required this.long,
    this.photo,
    this.reason,
  });
}
