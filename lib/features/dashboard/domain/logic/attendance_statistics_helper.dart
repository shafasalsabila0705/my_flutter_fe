import 'package:flutter_application_1/features/dashboard/data/models/attendance_model.dart';
import 'package:flutter_application_1/features/dashboard/domain/entities/attendance_stats_summary.dart';

class AttendanceStatisticsHelper {
  static AttendanceStatsSummary calculate(AttendanceRecapModel data) {
    int present = data.present;
    int lateNoPermit = data.late;
    int latePermitted = data.lateAllowed;
    int permission = data.permission;
    int leave = data.leave;
    int unknown = data.alpha;
    int notPresent = data.notPresent; // Added

    final details = data.details ?? [];
    final hasDetails = details.isNotEmpty;
    final isSummaryEmpty =
        (present + lateNoPermit + permission + leave + unknown) == 0;

    // Recalculate if summary is empty OR if we want to ensure sync with list
    if (hasDetails) {
      // Reset counters to be safe if we rely on list aggregation
      if (isSummaryEmpty) {
        present = 0;
        lateNoPermit = 0;
        latePermitted = 0;
        permission = 0;
        leave = 0;
        unknown = 0;
        notPresent = 0;
      }

      if (isSummaryEmpty) {
        for (var item in details) {
          if (item is Map) {
            // Check 'stats' object for Monthly Summary format
            if (item['stats'] is Map) {
              final stats = item['stats'];
              // Helper to safe parse
              int parse(dynamic v) =>
                  (v is int) ? v : int.tryParse(v.toString()) ?? 0;

              int h = parse(
                stats['h'] ?? stats['hadir'] ?? stats['hadir_tepat_waktu'],
              );
              int totalHadir = parse(
                stats['total_kehadiran'] ?? stats['total'],
              );

              // Lateness - we might not be able to distinguish permit here easily unless backend gives it
              // Assuming 'tl_cp_diizinkan' exists or similar
              int latePermittedLocal = parse(stats['tl_cp_diizinkan']);
              int lateNoPermitLocal =
                  parse(stats['tl']) +
                  parse(stats['cp']) +
                  parse(stats['tl_cp']);

              // Fallback if detailed keys missing but 'late' present
              // We can't distinguish, so put in lateNoPermit

              // If h is missing but we have total, derive it
              if (h == 0 && totalHadir > 0) {
                h = (totalHadir - (latePermittedLocal + lateNoPermitLocal))
                    .clamp(0, 31);
              }

              present += h;
              lateNoPermit += lateNoPermitLocal;
              latePermitted += latePermittedLocal;
              permission += parse(stats['i'] ?? stats['izin']);
              leave += parse(stats['c'] ?? stats['cuti']);
              unknown += parse(stats['tk'] ?? stats['alfa']);
              notPresent += parse(stats['not_present'] ?? stats['belum_absen']);
            } else {
              // Daily Log Format
              final status =
                  (item['status'] ?? item['status_kehadiran'] ?? 'ALPHA')
                      .toString()
                      .toUpperCase();
              if (status.contains('HADIR') || status.contains('TEPAT')) {
                present++;
              } else if (status.contains('TERLAMBAT') ||
                  status.contains('CP') ||
                  status.contains('PULANG')) {
                // Try to detect permission
                if (status.contains('DISETUJUI') ||
                    status.contains('DITERIMA') ||
                    status.contains('IZIN')) {
                  latePermitted++;
                } else {
                  lateNoPermit++;
                }
              } else if (status.contains('IZIN') ||
                  status.contains('SAKIT') ||
                  status.contains('DINAS') ||
                  status.contains('TUGAS')) {
                permission++;
              } else if (status.contains('CUTI')) {
                leave++;
              } else if (status.contains('ALPHA') || status.contains('TANPA')) {
                unknown++;
              } else {
                // Assuming anything else is Belum Absen? Or just unknown?
                // Usually 'BELUM_ABSEN'
                if (status.contains('BELUM')) {
                  // Ignored
                } else {
                  unknown++;
                }
              }
            }
          }
        }
      }
    }

    // Calculate Total
    final total =
        present +
        lateNoPermit +
        latePermitted +
        permission +
        leave +
        unknown +
        notPresent;
    final presentPercentage = total > 0 ? ((present / total) * 100).toInt() : 0;

    return AttendanceStatsSummary(
      present: present,
      lateNoPermit: lateNoPermit,
      latePermitted: latePermitted,
      permission: permission,
      leave: leave,
      unknown: unknown,
      notPresent: notPresent,
      total: total,
      presentPercentage: presentPercentage,
    );
  }
}
