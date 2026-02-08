import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/koreksi_repository.dart';
import '../../data/models/attendance_model.dart';

class GetTodayAttendanceUseCase extends UseCase<AttendanceModel?, void> {
  final AttendanceRepository _attendanceRepository;
  final KoreksiRepository _koreksiRepository;

  GetTodayAttendanceUseCase(
    this._attendanceRepository,
    this._koreksiRepository,
  );

  @override
  Future<Stream<AttendanceModel?>> buildUseCaseStream(void params) async {
    final controller = StreamController<AttendanceModel?>();
    try {
      // 1. Try Get Today Status from API
      try {
        final result = await _attendanceRepository.getTodayStatus();
        if (result['data'] != null) {
          final Map<String, dynamic> attendanceData = Map<String, dynamic>.from(
            result['data'],
          );
          if (result['jadwal'] != null) {
            attendanceData['jadwal'] = result['jadwal'];
          }
          controller.add(AttendanceModel.fromJson(attendanceData));
          controller.close();
          return controller.stream;
        }
      } catch (e) {
        // Continue to fallback
      }

      // 2. Fallback: Check History for Today
      try {
        final history = await _attendanceRepository.getHistory();
        final now = DateTime.now();
        final todayItem = history.firstWhere(
          (element) {
            if (element.date == null) return false;
            try {
              final date = DateTime.parse(element.date!);
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            } catch (_) {
              return false;
            }
          },
          orElse: () =>
              const AttendanceModel(status: 'UNKNOWN', checkInTime: '-'),
        );

        if (todayItem.status != 'UNKNOWN') {
          controller.add(todayItem);
          controller.close();
          return controller.stream;
        }
      } catch (_) {}

      // 3. Fallback: Check Correction
      try {
        final corrections = await _koreksiRepository.getHistory();
        final now = DateTime.now();
        final todayCorrection = corrections.firstWhere((element) {
          try {
            if (element.tanggalKehadiran == null) return false;
            final date = DateTime.parse(element.tanggalKehadiran!);
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          } catch (_) {
            return false;
          }
        }, orElse: () => throw Exception('Not Found'));

        final displayStatus = "DL - ${todayCorrection.status}";
        final attendance = AttendanceModel(
          status: displayStatus.toUpperCase(),
          checkInTime: "DINAS LUAR",
          checkOutTime: "-",
          date: todayCorrection.tanggalKehadiran,
        );
        controller.add(attendance);
        controller.close();
        return controller.stream;
      } catch (_) {}

      // If nothing found
      controller.add(null);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}
