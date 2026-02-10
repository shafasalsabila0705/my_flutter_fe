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
      final now = DateTime.now();

      // 1. Try Get Today Status from API
      try {
        final result = await _attendanceRepository.getTodayStatus();
        if (result['data'] != null || result['jadwal'] != null) {
          final Map<String, dynamic> attendanceData = result['data'] != null
              ? Map<String, dynamic>.from(result['data'])
              : <String, dynamic>{};

          if (result['jadwal'] != null) {
            attendanceData['jadwal'] = result['jadwal'];
          }

          AttendanceModel model = AttendanceModel.fromJson(attendanceData);

          // ENHANCEMENT: Populate date if missing but schedule/data exists
          if (model.date == null || model.date!.isEmpty) {
            model = model.copyWith(date: now.toIso8601String().split('T')[0]);
          }

          // Relaxed Today Check:
          // 1. Has check-in time, OR
          // 2. Has scheduled check-in time (from API), OR
          // 3. Date matches today
          final bool hasCheckIn = model.checkInTime != '-';
          final bool hasSchedule =
              model.scheduledCheckInTime != null &&
              model.scheduledCheckInTime != '-';
          final bool isToday = _isSameDay(DateTime.parse(model.date!), now);

          if (hasCheckIn || hasSchedule || isToday) {
            controller.add(model);
            controller.close();
            return controller.stream;
          }
        }
      } catch (e) {
        // Continue to fallback
      }

      // 2. Advanced Fallback: Check History for Today OR Yesterday (within 6 hours)
      try {
        final history = await _attendanceRepository.getHistory();

        // Find Today's Item
        final todayItem = history.where((element) {
          if (element.date == null) return false;
          try {
            final date = DateTime.parse(element.date!);
            return _isSameDay(date, now);
          } catch (_) {
            return false;
          }
        }).toList();

        if (todayItem.isNotEmpty) {
          controller.add(todayItem.first);
          controller.close();
          return controller.stream;
        }

        // If NO record for today, check Yesterday
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayItem = history.where((element) {
          if (element.date == null) return false;
          try {
            final date = DateTime.parse(element.date!);
            return _isSameDay(date, yesterday);
          } catch (_) {
            return false;
          }
        }).toList();

        if (yesterdayItem.isNotEmpty) {
          final item = yesterdayItem.first;
          if (item.checkOutTime != null && item.checkOutTime != '-') {
            try {
              // Parse checkout time from yesterday's record
              final parts = item.checkOutTime!.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);
              final checkoutDateTime = DateTime(
                yesterday.year,
                yesterday.month,
                yesterday.day,
                hour,
                minute,
              );

              // If now is within 6 hours of yesterday's checkout, show it
              if (now.difference(checkoutDateTime).inHours < 6) {
                controller.add(item);
                controller.close();
                return controller.stream;
              }
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 3. Fallback: Check Correction for Today
      try {
        final corrections = await _koreksiRepository.getHistory();
        final todayCorrection = corrections.firstWhere((element) {
          try {
            if (element.tanggalKehadiran == null) return false;
            final date = DateTime.parse(element.tanggalKehadiran!);
            return _isSameDay(date, now);
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

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
