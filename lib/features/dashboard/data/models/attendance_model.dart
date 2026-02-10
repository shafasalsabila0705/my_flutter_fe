import 'package:equatable/equatable.dart';

class AttendanceModel extends Equatable {
  final String status;
  final String? statusKeluar;
  final String? statusLokasiMasuk;
  final String? statusLokasiPulang;
  final String checkInTime;
  final String? checkOutTime;
  final double? distance;
  final String? checkInCoordinates; // Added field
  final String? date;
  final String? scheduledCheckInTime;
  final String? scheduledCheckOutTime;

  const AttendanceModel({
    required this.status,
    this.statusKeluar,
    this.statusLokasiMasuk,
    this.statusLokasiPulang,
    required this.checkInTime,
    this.checkOutTime,
    this.distance,
    this.checkInCoordinates,
    this.date,
    this.scheduledCheckInTime,
    this.scheduledCheckOutTime,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      status: json['status'] ?? json['status_masuk'] ?? 'UNKNOWN',
      statusKeluar: json['status_pulang'] ?? json['status_keluar'],
      statusLokasiMasuk:
          json['status_lokasi_masuk'] ??
          json['status_lokasi_checkin'] ??
          json['status_radius_masuk'] ??
          json['lokasi_masuk'] ??
          json['radius_masuk'],
      statusLokasiPulang:
          json['status_lokasi_pulang'] ??
          json['status_lokasi_keluar'] ??
          json['status_lokasi_checkout'] ??
          json['status_radius_pulang'] ??
          json['status_radius_keluar'] ??
          json['lokasi_pulang'] ??
          json['lokasi_keluar'] ??
          json['radius_pulang'] ??
          json['radius_keluar'],
      // Check for multiple possible keys for time
      checkInTime:
          json['jam_masuk_real'] ?? json['waktu_masuk'] ?? json['time'] ?? '-',
      checkOutTime:
          json['jam_pulang_real'] ??
          json['waktu_pulang'] ??
          json['check_out_time'],
      distance: (json['jarak'] as num?)?.toDouble(),
      checkInCoordinates: json['koordinat_masuk'],
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

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'status_pulang': statusKeluar,
      'status_lokasi_masuk': statusLokasiMasuk,
      'status_lokasi_pulang': statusLokasiPulang,
      'jam_masuk_real': checkInTime,
      'jam_pulang_real': checkOutTime,
      'jarak': distance,
      'koordinat_masuk': checkInCoordinates,
      'tanggal': date,
      'jam_masuk_jadwal': scheduledCheckInTime,
      'jam_pulang_jadwal': scheduledCheckOutTime,
    };
  }

  AttendanceModel copyWith({
    String? status,
    String? statusKeluar,
    String? statusLokasiMasuk,
    String? statusLokasiPulang,
    String? checkInTime,
    String? checkOutTime,
    double? distance,
    String? checkInCoordinates,
    String? date,
    String? scheduledCheckInTime,
    String? scheduledCheckOutTime,
  }) {
    return AttendanceModel(
      status: status ?? this.status,
      statusKeluar: statusKeluar ?? this.statusKeluar,
      statusLokasiMasuk: statusLokasiMasuk ?? this.statusLokasiMasuk,
      statusLokasiPulang: statusLokasiPulang ?? this.statusLokasiPulang,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      distance: distance ?? this.distance,
      checkInCoordinates: checkInCoordinates ?? this.checkInCoordinates,
      date: date ?? this.date,
      scheduledCheckInTime: scheduledCheckInTime ?? this.scheduledCheckInTime,
      scheduledCheckOutTime:
          scheduledCheckOutTime ?? this.scheduledCheckOutTime,
    );
  }

  @override
  List<Object?> get props => [
    status,
    statusKeluar,
    statusLokasiMasuk,
    statusLokasiPulang,
    checkInTime,
    checkOutTime,
    distance,
    checkInCoordinates,
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
  final int alpha; // Added Alpha (TK) field
  final List<dynamic>? details; // Enable details to capture list

  const AttendanceRecapModel({
    required this.present,
    required this.late,
    required this.permission,
    required this.leave,
    required this.alpha,
    this.details,
  });

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    // 0. NEW FORMAT: Check for 'bulan_ini' (Summary Object)
    if (json.containsKey('bulan_ini') && json['bulan_ini'] is Map) {
      final summary = json['bulan_ini'];
      return AttendanceRecapModel(
        present: summary['hadir_tepat_waktu'] ?? 0,
        late: (summary['tl_cp'] ?? 0) + (summary['tl_cp_diizinkan'] ?? 0),
        permission: summary['izin'] ?? 0,
        leave: summary['cuti'] ?? 0,
        alpha: summary['alfa'] ?? 0,
        details:
            json['details'] ??
            json['data'] ??
            json['list'] ??
            json['pegawai'] ??
            [],
      );
    }

    // 1. Check if 'data' is the source of truth and if it's a List (New Endpoint Format)
    if (json.containsKey('data') && json['data'] is List) {
      final list = json['data'] as List;
      int p = 0;
      int l = 0;
      int i = 0;
      int c = 0;
      int a = 0;

      for (var item in list) {
        if (item is Map) {
          final stats = item['stats'];
          if (stats is Map) {
            // Mapping Logic derived from Logs:
            // keys: c, cp, i, t1..t4, tk, tl, total_kehadiran
            // 'h' (Hadir Tepat Waktu) is MISSING in log.
            // 'total_kehadiran' seems to be the sum of all presence.

            int parse(dynamic val) {
              if (val == null) return 0;
              if (val is int) return val;
              return int.tryParse(val.toString()) ?? 0;
            }

            int lateCount =
                parse(stats['tl'] ?? stats['terlambat']) +
                parse(stats['cp'] ?? stats['pulang_cepat']) +
                parse(stats['t1']) +
                parse(stats['t2']) +
                parse(stats['t3']) +
                parse(stats['t4']);

            int cVal = parse(stats['c'] ?? stats['cuti']);
            int iVal = parse(stats['i'] ?? stats['izin']);
            int tkVal = parse(
              stats['tk'] ?? stats['alpha'] ?? stats['tanpa_keterangan'],
            );

            // If 'h' is missing, calculate it: Total - Late
            // New API seems to have 'total_kehadiran' as Net Present (excluding Alpha/Cuti/Izin)
            // So we only subtract Late to get "On Time".
            int total = parse(stats['total_kehadiran'] ?? stats['total']);
            int h = parse(stats['h'] ?? stats['hadir']);

            if (h == 0 && total > 0) {
              h = total - lateCount;
              if (h < 0) h = 0; // Prevent negative
            }

            p += h;
            l += lateCount;
            i += iVal;
            c += cVal;
            a += tkVal;
          }
        }
      }

      return AttendanceRecapModel(
        present: p,
        late: l,
        permission: i,
        leave: c,
        alpha: a,
        details: list,
      );
    }

    // 2. Standard Object Format (Old Endpoint)
    return AttendanceRecapModel(
      present: json['hadir'] ?? 0,
      late: json['terlambat'] ?? 0,
      permission: json['izin'] ?? 0,
      leave: json['cuti'] ?? 0,
      alpha: json['alpha'] ?? json['tk'] ?? 0,
      details:
          json['details'] ??
          json['detail'] ??
          json['list'] ??
          json['histories'] ??
          json['riwayat'] ??
          json['logs'] ??
          json['records'] ??
          json['data'],
    );
  }

  @override
  List<Object?> get props => [present, late, permission, leave, alpha, details];
}
