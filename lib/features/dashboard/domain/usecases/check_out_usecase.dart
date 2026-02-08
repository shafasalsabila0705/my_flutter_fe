import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';

class CheckOutUseCase extends UseCase<AttendanceModel, CheckOutParams> {
  final AttendanceRepository _repository;

  CheckOutUseCase(this._repository);

  @override
  Future<Stream<AttendanceModel>> buildUseCaseStream(
    CheckOutParams? params,
  ) async {
    final controller = StreamController<AttendanceModel>();
    try {
      if (params == null) throw Exception("Params null");

      final result = await _repository.checkOut(
        params.lat,
        params.long,
        reason: params.reason,
      );
      controller.add(result);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}

class CheckOutParams {
  final double lat;
  final double long;
  final String? reason;

  CheckOutParams({required this.lat, required this.long, this.reason});
}
