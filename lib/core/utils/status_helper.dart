class StatusHelper {
  static String mapStatusToIndonesian(String? status) {
    if (status == null) return "-";
    final s = status.toUpperCase();

    if (s.contains('APPROVE') ||
        s.contains('SETUJU') ||
        s.contains('DITERIMA')) {
      return 'DISETUJUI';
    }
    if (s.contains('REJECT') || s.contains('TOLAK')) {
      return 'DITOLAK';
    }
    if (s.contains('PENDING') ||
        s.contains('MENUNGGU') ||
        s.contains('WAITING')) {
      return 'MENUNGGU';
    }
    return status;
  }
}
