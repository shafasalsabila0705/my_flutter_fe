enum RequestType {
  cuti("Cuti", "Jenis Cuti"),
  izin("Izin", "Jenis Izin"),
  koreksi("Koreksi", "Jenis Koreksi"),
  unknown("Lainnya", "Jenis Pengajuan");

  final String name;
  final String label;

  const RequestType(this.name, this.label);

  static RequestType fromString(String? type) {
    if (type == null) return RequestType.unknown;
    
    final normalizedType = type.toUpperCase().trim();
    
    if (normalizedType.contains("CUTI")) return RequestType.cuti;
    if (normalizedType.contains("IZIN")) return RequestType.izin;
    // Common Correction types
    if (normalizedType.contains("KOREKSI") || 
        normalizedType.contains("TERLAMBAT") ||
        normalizedType.contains("PULANG") ||
        normalizedType.contains("LUAR")) return RequestType.koreksi;

    return RequestType.unknown;
  }
}
