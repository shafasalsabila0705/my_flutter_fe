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
  final double? officeLat;
  final double? officeLong;
  final double? officeRadius;

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
    this.officeLat,
    this.officeLong,
    this.officeRadius,
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
      // Parse Scheduled Times (Try specific jadwal first, then generic shift, then flat)
      scheduledCheckInTime:
          json['jadwal']?['jam_masuk'] ??
          json['shift']?['jam_masuk'] ??
          json['jam_masuk_jadwal'] ??
          json['jam_masuk'],

      scheduledCheckOutTime:
          json['jadwal']?['jam_pulang'] ??
          json['shift']?['jam_pulang'] ??
          json['jam_pulang_jadwal'] ??
          json['jam_pulang'],
      officeLat:
          (json['lokasi']?['latitude'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble(),
      officeLong:
          (json['lokasi']?['longitude'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble(),
      officeRadius:
          (json['lokasi']?['radius_meter'] as num?)?.toDouble() ??
          (json['radius_meter'] as num?)?.toDouble(),
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
      'office_latitude': officeLat,
      'office_longitude': officeLong,
      'office_radius': officeRadius,
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
    double? officeLat,
    double? officeLong,
    double? officeRadius,
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
      officeLat: officeLat ?? this.officeLat,
      officeLong: officeLong ?? this.officeLong,
      officeRadius: officeRadius ?? this.officeRadius,
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
    officeLat,
    officeLong,
    officeRadius,
  ];
}

class AttendanceRecapModel extends Equatable {
  final int present;
  final int late;
  final int permission;
  final int leave;
  final int alpha;
  final int lateAllowed;
  final int notPresent; // Added
  final List<dynamic>? details;

  const AttendanceRecapModel({
    required this.present,
    required this.late,
    required this.permission,
    required this.leave,
    required this.alpha,
    required this.lateAllowed,
    required this.notPresent,
    this.details,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory AttendanceRecapModel.fromJson(Map<String, dynamic> json) {
    // 0. NEW FORMAT: Check for 'bulan_ini' (Summary Object)
    if (json.containsKey('bulan_ini') && json['bulan_ini'] is Map) {
      final summary = json['bulan_ini'];
      return AttendanceRecapModel(
        present: _parseInt(summary['hadir_tepat_waktu']),
        late: _parseInt(summary['tl_cp']),
        lateAllowed: _parseInt(summary['tl_cp_diizinkan']),
        permission: _parseInt(summary['izin']),
        leave: _parseInt(summary['cuti']),
        alpha: _parseInt(summary['alfa']),
        notPresent: _parseInt(summary['belum_absen']),
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
        lateAllowed: 0, // Fallback for list format
        permission: i,
        leave: c,
        alpha: a,
        notPresent: 0,
        details: list,
      );
    }

    // 2. Standard Object Format (Old Endpoint)
    return AttendanceRecapModel(
      present: _parseInt(json['hadir']),
      late: _parseInt(json['terlambat']),
      lateAllowed: 0,
      permission: _parseInt(json['izin']),
      leave: _parseInt(json['cuti']),
      alpha: _parseInt(json['alpha'] ?? json['tk']),
      notPresent: _parseInt(json['belum_absen'] ?? json['not_present']),
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
  List<Object?> get props => [
    present,
    late,
    lateAllowed,
    permission,
    leave,
    alpha,
    notPresent,
    details,
  ];
}
