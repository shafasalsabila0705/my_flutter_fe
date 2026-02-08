import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';

class GetAttendanceHistoryUseCase extends UseCase<List<AttendanceModel>, void> {
  final AttendanceRepository _repository;

  GetAttendanceHistoryUseCase(this._repository);

  @override
  Future<Stream<List<AttendanceModel>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<AttendanceModel>>();
    try {
      final history = await _repository.getHistory();
      controller.add(history);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}
