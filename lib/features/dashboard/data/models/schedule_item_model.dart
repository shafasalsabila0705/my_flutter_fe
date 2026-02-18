
class ScheduleItemModel {
  final int? id;
  final String date;
  final String? shiftName;
  final String? shiftStart;
  final String? shiftEnd;
  final String? status;
  final String? realStart;
  final String? realEnd;

  ScheduleItemModel({
    this.id,
    required this.date,
    this.shiftName,
    this.shiftStart,
    this.shiftEnd,
    this.status,
    this.realStart,
    this.realEnd,
  });

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: json['id'],
      date: json['tanggal'],
      shiftName: json['nama_shift'],
      shiftStart: json['jam_masuk_shift'],
      shiftEnd: json['jam_pulang_shift'],
      status: json['status'],
      realStart: json['jam_masuk_real'],
      realEnd: json['jam_pulang_real'],
    );
  }
}
