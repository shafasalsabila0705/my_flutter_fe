import 'package:equatable/equatable.dart';

class AttendanceModel extends Equatable {
  final String status;
  final String checkInTime;
  final String? checkOutTime;
  final double? distance;
  final String? date;
  final String? scheduledCheckInTime;
  final String? scheduledCheckOutTime;

  const AttendanceModel({
    required this.status,
    required this.checkInTime,
    this.checkOutTime,
    this.distance,
    this.date,
    this.scheduledCheckInTime,
    this.scheduledCheckOutTime,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      status: json['status'] ?? json['status_masuk'] ?? 'UNKNOWN',
      // Check for multiple possible keys for time
      checkInTime:
          json['jam_masuk_real'] ?? json['waktu_masuk'] ?? json['time'] ?? '-',
      checkOutTime:
          json['jam_pulang_real'] ??
          json['waktu_pulang'] ??
          json['check_out_time'],
      distance: (json['jarak'] as num?)?.toDouble(),
      date: json['tanggal'],
      // Parse Scheduled Times (Try flat, then nested)
      scheduledCheckInTime:
          json['jam_masuk'] ??
          json['jam_masuk_jadwal'] ??
          json['shift']?['jam_masuk'] ??
          json['jadwal']?['jam_masuk'],

      scheduledCheckOutTime:
          json['jam_pulang'] ??
          json['jam_pulang_jadwal'] ??
          json['shift']?['jam_pulang'] ??
          json['jadwal']?['jam_pulang'],
    );
  }

  @override
  List<Object?> get props => [
    status,
    checkInTime,
    checkOutTime,
    distance,
    date,
    scheduledCheckInTime,
    scheduledCheckOutTime,
  ];
}

class AttendanceRecapModel extends Equatable {
  final int present;
  final int late;
  final int permission;
  final int leave;
  // final List<AttendanceModel> details;

  const AttendanceRecapModel({
    required this.present,
    required this.late,
    required this.permission,
    required this.leave,
  });

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecapModel(
      present: json['hadir'] ?? 0,
      late: json['terlambat'] ?? 0,
      permission: json['izin'] ?? 0,
      leave: json['cuti'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [present, late, permission, leave];
}
