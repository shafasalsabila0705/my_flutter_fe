import 'package:equatable/equatable.dart';

class AttendanceStatsSummary extends Equatable {
  final int present;
  final int lateNoPermit;
  final int latePermitted;
  final int permission;
  final int leave;
  final int unknown;
  final int notPresent; // Added
  final int total;
  final int presentPercentage;

  const AttendanceStatsSummary({
    required this.present,
    required this.lateNoPermit,
    required this.latePermitted,
    required this.permission,
    required this.leave,
    required this.unknown,
    required this.notPresent,
    required this.total,
    required this.presentPercentage,
  });

  @override
  List<Object> get props => [
    present,
    lateNoPermit,
    latePermitted,
    permission,
    leave,
    unknown,
    notPresent,
    total,
    presentPercentage,
  ];
}
