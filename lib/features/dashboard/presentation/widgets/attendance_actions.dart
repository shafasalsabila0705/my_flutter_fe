import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/services/location_service.dart';
import '../../../common/presentation/pages/camera_page.dart';

import '../../data/models/attendance_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/constants/app_icons.dart';

class AttendanceActions extends StatefulWidget {
  final Future<AttendanceModel> Function(
    double lat,
    double long, {
    String? reason,
  })
  onCheckIn;
  final Future<AttendanceModel> Function(
    File photo,
    double lat,
    double long, {
    String? reason,
  })?
  onCheckInWithPhoto;
  final Future<AttendanceModel> Function(
    double lat,
    double long, {
    String? reason,
  })
  onCheckOut;
  final Future<AttendanceModel> Function(
    File photo,
    double lat,
    double long, {
    String? reason,
  })?
  onCheckOutWithPhoto;
  final bool isOutsideRadius;
  final Future<bool> Function() onValidateSchedule; // Added

  const AttendanceActions({
    super.key,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onValidateSchedule, // Added
    this.initialData,
    this.onCheckInWithPhoto,
    this.onCheckOutWithPhoto,
    this.isOutsideRadius = false,
  });

  final AttendanceModel? initialData;

  @override
  State<AttendanceActions> createState() => _AttendanceActionsState();
}

class _AttendanceActionsState extends State<AttendanceActions> {
  bool _isClockedIn = false;
  String _clockInTime = "-- : --";
  String _clockOutTime = "-- : --";
  bool _isAttendanceComplete = false;
  bool _isLoading = false;

  // Status Flags
  bool _isLate = false;
  bool _isEarlyLeave = false;

  // Location Validation State
  bool _checkInLocationValid = true;
  bool _checkOutLocationValid = true;

  @override
  void initState() {
    super.initState();
    _syncWithInitialData();
  }

  @override
  void didUpdateWidget(covariant AttendanceActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _syncWithInitialData();
    }
  }

  void _syncWithInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      final hasCheckIn = data.checkInTime.isNotEmpty && data.checkInTime != '-';
      final hasCheckOut =
          data.checkOutTime != null &&
          data.checkOutTime!.isNotEmpty &&
          data.checkOutTime != '-';

      if (mounted) {
        setState(() {
          _isClockedIn = hasCheckIn && !hasCheckOut;
          _clockInTime = hasCheckIn ? data.checkInTime : "-- : --";
          _clockOutTime = hasCheckOut ? data.checkOutTime! : "-- : --";
          _isAttendanceComplete = hasCheckOut;

          // DECOUPLED VALIDATION LOGIC
          // 1. Check In Validation (Recalculated from times for persistence)
          _isLate = false;
          if (hasCheckIn) {
            final String checkInStatus = data.status.toUpperCase();
            // Prioritize Database Status String
            if (checkInStatus.contains('TERLAMBAT') ||
                checkInStatus.contains('TELAT')) {
              _isLate = true;
            } else if (checkInStatus.contains('HADIR')) {
              _isLate = false;
            } else {
              // Fallback to time calculation
              final String sTimeStr =
                  (data.scheduledCheckInTime != null &&
                      data.scheduledCheckInTime != '-')
                  ? data.scheduledCheckInTime!
                  : "08:00"; // Robust default fallback

              try {
                final partsS = sTimeStr.split(':');
                final sHour = int.parse(partsS[0]);
                final sMinute = int.parse(partsS[1]);

                final partsR = data.checkInTime.split(':');
                final rHour = int.parse(partsR[0]);
                final rMinute = int.parse(partsR[1]);

                if (rHour > sHour || (rHour == sHour && rMinute > sMinute)) {
                  _isLate = true;
                }
              } catch (_) {}
            }
          }

          // Check In Location: Prioritize Database 'status_lokasi_masuk'
          if (data.statusLokasiMasuk != null &&
              data.statusLokasiMasuk!.isNotEmpty) {
            final String locMasuk = data.statusLokasiMasuk!.toUpperCase();
            _checkInLocationValid =
                locMasuk.contains('VALID') && !locMasuk.contains('INVALID');
          } else {
            // Fallback to coordinates calculation first, then check main status
            double? checkInDist = data.distance;
            if (data.checkInCoordinates != null) {
              try {
                final parts = data.checkInCoordinates!.split(',');
                final lat = double.parse(parts[0].trim());
                final long = double.parse(parts[1].trim());
                checkInDist = LocationService().calculateDistance(
                  lat,
                  long,
                  LocationService().officeLat,
                  LocationService().officeLong,
                );
              } catch (_) {}
            }

            final bool distValid = (checkInDist != null)
                ? checkInDist <= LocationService().radiusInMeters
                : true;

            final String checkInStatusUpper = data.status.toUpperCase();
            final bool statusIndicatesLuar =
                checkInStatusUpper.contains('LUAR') ||
                checkInStatusUpper.contains('DL') ||
                checkInStatusUpper.contains('INVALID');

            _checkInLocationValid = distValid && !statusIndicatesLuar;
          }

          // 2. Check Out Validation
          if (hasCheckOut) {
            final String checkOutStatus =
                (data.statusKeluar != null && data.statusKeluar!.isNotEmpty)
                ? data.statusKeluar!.toUpperCase()
                : data.status.toUpperCase();

            // Prioritize Database Status String
            if (checkOutStatus.contains('CEPAT') ||
                checkOutStatus.contains('AWAL')) {
              _isEarlyLeave = true;
            } else if (checkOutStatus.contains('PULANG')) {
              _isEarlyLeave = false;
            } else {
              // Fallback to time calculation
              final String sTimeStr =
                  (data.scheduledCheckOutTime != null &&
                      data.scheduledCheckOutTime != '-')
                  ? data.scheduledCheckOutTime!
                  : "16:00"; // Robust default fallback

              try {
                final partsS = sTimeStr.split(':');
                final sHour = int.parse(partsS[0]);
                final sMinute = int.parse(partsS[1]);

                final partsR = data.checkOutTime!.split(':');
                final rHour = int.parse(partsR[0]);
                final rMinute = int.parse(partsR[1]);

                if (rHour < sHour || (rHour == sHour && rMinute < sMinute)) {
                  _isEarlyLeave = true;
                } else {
                  _isEarlyLeave = false;
                }
              } catch (_) {}
            }

            // debugPrint("DEBUG: statusLokasiPulang = ${data.statusLokasiPulang}");
            // debugPrint("DEBUG: checkOutStatus = $checkOutStatus");

            // Check Out Location: Prioritize Database 'status_lokasi_pulang'
            if (data.statusLokasiPulang != null &&
                data.statusLokasiPulang!.isNotEmpty) {
              final String locPulang = data.statusLokasiPulang!.toUpperCase();
              _checkOutLocationValid =
                  locPulang.contains('VALID') && !locPulang.contains('INVALID');
            } else {
              // Fallback to previous logic:
              // If current status (masuk or keluar) is LUAR RADIUS and it's Checked Out,
              // then Check Out might be the one that's invalid.
              final String checkOutStatusUpper = checkOutStatus.toUpperCase();
              final bool isLuar =
                  checkOutStatusUpper.contains('LUAR') ||
                  checkOutStatusUpper.contains('DL') ||
                  checkOutStatusUpper.contains('INVALID');
              _checkOutLocationValid = !isLuar;
            }
          }
        });
      }
    }
  }

  Future<void> _handleAttendanceAction() async {
    if (_isLoading) return;

    // Prevent action if attendance is already completed for the day
    if (_isAttendanceComplete) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Absensi Selesai",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Anda sudah menyelesaikan absensi hari ini. Silakan kembali besok.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Oke",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // --- STEP 1: STRICT SCHEDULE VALIDATION (Blocking) ---
    // Added logic per user request: "Cek Jadwal Terlebih Dahulu"
    debugPrint("Checking Schedule Integrity via API...");
    final bool hasSchedule = await widget.onValidateSchedule();
    debugPrint("Schedule Check Result: $hasSchedule");

    if (!hasSchedule) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Anda tidak memiliki jadwal hari ini."),
          backgroundColor: Colors.red,
        ),
      );
      return; // STOP PROCESS
    }

    final bool isCheckingIn = !_isClockedIn;

    // --- PRE-VALIDATION (Schedule & Time) ---
    // Note: Since we validated 'existence', we can trust initialData is updated by the provider
    // OR we can rely on the fact that validator returned true.

    // We still keep the time limit logic, but make it non-blocking if data is weird,
    // OR strict if we trust validator.

    final scheduleData = widget.initialData;
    final now = DateTime.now();

    if (isCheckingIn) {
      // 1. Check if Schedule Exists (Double Check)
      final scheduleIn = scheduleData?.scheduledCheckInTime;
      if (scheduleIn == null || scheduleIn.isEmpty || scheduleIn == '-') {
        // Should not happen if validator passed, but just in case
        // We allow proceed or show error?
        // If Validator said "True", it means API said "OK".
        // But maybe widget.initialData isn't rebuilt yet?
        // In Flutter, provider notification should rebuild this widget.
        // Let's assume it's updated.
      }

      // 2. Check Early Time Limit
      if (scheduleIn != null && scheduleIn.contains(':')) {
        try {
          final parts = scheduleIn.split(':');
          final sHour = int.parse(parts[0]);
          final sMinute = int.parse(parts[1]);
          final sDate = DateTime(now.year, now.month, now.day, sHour, sMinute);

          // Allow check-in 1 hour before scheduled time
          final earlyLimit = sDate.subtract(const Duration(hours: 1));

          if (now.isBefore(earlyLimit)) {
            final diff = earlyLimit.difference(now).inMinutes;
            final fmt =
                "${earlyLimit.hour.toString().padLeft(2, '0')}:${earlyLimit.minute.toString().padLeft(2, '0')}";

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Belum saatnya absen. Bisa absen mulai pukul $fmt ($diff menit lagi).",
                ),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        } catch (e) {
          debugPrint("Error parsing schedule time: $e");
        }
      }
    } else {
      // Check Out Validation
      // 1. Check if Schedule Exists
      final scheduleOut = scheduleData?.scheduledCheckOutTime;
      if (scheduleOut == null || scheduleOut.isEmpty || scheduleOut == '-') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Anda tidak memiliki jadwal pulang hari ini."),
          ),
        );
        return;
      }

      // 2. Check Late Time Limit
      try {
        final parts = scheduleOut.split(':');
        final sHour = int.parse(parts[0]);
        final sMinute = int.parse(parts[1]);
        final sDate = DateTime(now.year, now.month, now.day, sHour, sMinute);

        final lateLimit = sDate.add(const Duration(hours: 2));

        if (now.isAfter(lateLimit)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Batas waktu absen pulang telah habis (Maksimal 2 jam setelah jadwal).",
              ),
            ),
          );
          return;
        }
      } catch (e) {
        // Ignore parsing error
      }
    }
    // ----------------------------------------

    // Check-out Validation for Early Leave (Moved inside Try/Catch or handled before)
    // We handle Early Leave Reason collection here (before location check to save battery/time if cancelled)
    // AND Late Check In Reason collection.

    String? actionReason;

    if (isCheckingIn) {
      // Late reason collection removed as per requirement. Justification handled in History.
    } else {
      // CHECK EARLY LEAVE
      bool isEarly = false;
      // Parse Scheduled Time from initialData if available
      if (widget.initialData?.scheduledCheckOutTime != null &&
          widget.initialData!.scheduledCheckOutTime != '-' &&
          widget.initialData!.scheduledCheckOutTime!.contains(':')) {
        try {
          final parts = widget.initialData!.scheduledCheckOutTime!.split(':');
          final scheduledHour = int.parse(parts[0]);
          final scheduledMinute = int.parse(parts[1]);

          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduledHour,
            scheduledMinute,
          );

          if (now.isBefore(scheduledTime)) {
            isEarly = true;
          }
        } catch (e) {
          if (now.hour < 16) isEarly = true;
        }
      } else {
        if (now.hour < 16) isEarly = true;
      }

      if (isEarly && !widget.isOutsideRadius) {
        if (!mounted) return;
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFB300),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Konfirmasi Pulang Cepat",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Yakin anda ingin pulang cepat?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Ya, Pulang"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (confirmed != true) return; // Cancelled or false
      }
    }

    setState(() => _isLoading = true);

    try {
      // Get real location
      final position = await LocationService().getCurrentPosition();
      if (position == null) {
        throw Exception("Gagal mendapatkan lokasi. Pastikan GPS aktif.");
      }
      final double lat = position.latitude;
      final double long = position.longitude;

      AttendanceModel result;

      if (isCheckingIn) {
        if (widget.isOutsideRadius && widget.onCheckInWithPhoto != null) {
          // ... (existing check-in with photo logic)
          if (!mounted) return;

          final File? photo = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPage(position: position),
            ),
          );

          if (photo == null) {
            setState(() => _isLoading = false);
            return;
          }

          String? reason;
          if (mounted) {
            reason = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                String inputReason = "";
                return AlertDialog(
                  title: const Text("Alasan Dinas Luar"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Anda berada di luar radius kantor. Masukkan catatan/alasan aktivitas Anda.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Contoh: Rapat di Kantor Gubernur",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => inputReason = value,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, inputReason),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29B6F6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Kirim Absen"),
                    ),
                  ],
                );
              },
            );

            if (reason == null) {
              setState(() => _isLoading = false);
              return;
            }
          }

          result = await widget.onCheckInWithPhoto!(
            photo,
            lat,
            long,
            reason: reason,
          );
        } else {
          result = await widget.onCheckIn(lat, long, reason: actionReason);
        }
      } else {
        // CHECK OUT
        if (widget.isOutsideRadius && widget.onCheckOutWithPhoto != null) {
          // Outside Radius Check Out with Photo
          if (!mounted) return;

          final File? photo = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPage(position: position),
            ),
          );

          if (photo == null) {
            setState(() => _isLoading = false);
            return;
          }

          // Reason for Outside Radius Check Out
          String? reason;
          if (mounted) {
            reason = await showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                String inputReason = "";
                return AlertDialog(
                  title: const Text("Alasan Pulang Dinas Luar"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Anda berada di luar radius kantor saat pulang. Masukkan catatan/alasan Anda.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Contoh: Selesai Rapat di Kantor Gubernur",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => inputReason = value,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, inputReason),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29B6F6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Kirim Absen"),
                    ),
                  ],
                );
              },
            );

            if (reason == null) {
              setState(() => _isLoading = false);
              return;
            }
          }

          result = await widget.onCheckOutWithPhoto!(
            photo,
            lat,
            long,
            reason: reason,
          );
        } else {
          // Standard Check Out
          result = await widget.onCheckOut(lat, long, reason: actionReason);
        }
      }

      if (!mounted) return;

      final String actionLabel = isCheckingIn ? "Masuk" : "Pulang";
      final String formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Determine status logic based on RESULT from server
      String statusNote = result.status;
      Color statusColor = Colors.green;

      // Logic Variables used for State update later
      bool currentActionIsLate = false;
      bool currentActionIsEarly = false;

      // Handle "Late" Logic (Server Response Priority + Robust Fallback)
      if (isCheckingIn) {
        currentActionIsLate =
            statusNote.toLowerCase().contains('telat') ||
            statusNote.toLowerCase().contains('terlambat');

        // Fallback: Check if current time is after scheduled time
        if (!currentActionIsLate &&
            widget.initialData?.scheduledCheckInTime != null) {
          try {
            final parts = widget.initialData!.scheduledCheckInTime!.split(':');
            final sHour = int.parse(parts[0]);
            final sMinute = int.parse(parts[1]);
            final sTime = DateTime(
              now.year,
              now.month,
              now.day,
              sHour,
              sMinute,
            );
            if (now.isAfter(sTime)) {
              currentActionIsLate = true;
            }
          } catch (_) {}
        }

        if (currentActionIsLate) {
          statusColor = Colors.redAccent;
        }
      }

      // Handle "Early Leave" Logic
      if (!isCheckingIn) {
        // Reuse same logic...
        final bool isEarlyLeaveServer =
            statusNote.toLowerCase().contains('cepat') ||
            statusNote.toLowerCase().contains('awal');

        currentActionIsEarly = isEarlyLeaveServer;

        if (currentActionIsEarly) {
          statusColor = Colors.orange;
        }
      }

      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          Future.delayed(const Duration(seconds: 3), () {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF29B6F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF29B6F6),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Absensi $actionLabel Berhasil",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Show Time
                  Text(
                    "Pukul: $formattedTime",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  // Show Status (e.g., Terlambat / Pulang Cepat)
                  if (statusNote.isNotEmpty && statusNote != "UNKNOWN")
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusNote.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ).then((_) {
        setState(() {
          if (isCheckingIn) {
            _isClockedIn = true;
            _clockInTime = formattedTime;
            _isLate = currentActionIsLate; // Update Late Status
            _checkInLocationValid =
                (!statusNote.toUpperCase().contains('LUAR') &&
                    !statusNote.toUpperCase().contains('DL')) &&
                (result.distance == null ||
                    result.distance! <= LocationService().radiusInMeters);

            // 1. Notifikasi Absen Masuk Berhasil & Jadwal Reminder
            // Moved to DashboardNotifier to follow Architecture Guide
          } else {
            // Checking Out
            _isClockedIn = false;
            _clockOutTime = formattedTime;
            _isEarlyLeave = currentActionIsEarly; // Update Early Status
            _isAttendanceComplete = true; // Lock for the day

            // Robust Validation for CheckOut
            double? dist = result.distance;
            // Fallback: If server didn't return distance, calculate it locally
            if (dist == null) {
              try {
                dist = LocationService().calculateDistance(
                  lat,
                  long,
                  LocationService().officeLat,
                  LocationService().officeLong,
                );
              } catch (_) {}
            }

            final bool isLuar =
                statusNote.toUpperCase().contains('LUAR') ||
                statusNote.toUpperCase().contains('DL') ||
                (dist != null && dist > LocationService().radiusInMeters);

            _checkOutLocationValid = !isLuar;

            // 3. Notifikasi Absen Pulang Berhasil
            // Moved to DashboardNotifier to follow Architecture Guide
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      
      // Ignore silent errors
      if (errorMsg.contains("Holiday Prevention") ||
          errorMsg.contains("Holiday prevention")) {
        return;
      }

      // Check for Fake GPS Error
      if (errorMsg.contains("Fake GPS") || errorMsg.contains("lokasi palsu")) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Akses Ditolak",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMsg.replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Tutup"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: $errorMsg")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define Colors based on state
    final Color primaryColor = _isClockedIn
        ? const Color(0xFFFFB300)
        : const Color(0xFF29B6F6); // Yellow : Blue
    final String buttonLabel = _isClockedIn ? "PULANG" : "MASUK";

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0.0,
      ), // Padding handled by parent container now? Or keep it?
      // Since it's inside the glass card, maybe reduce horizontal padding?
      // Let's keep it to ensure button is centered.
      child: Column(
        children: [
          // White Clock In Button (Solid/Premium)
          Center(
            child: Container(
              height: 160, // Increased from 140 to 160
              width: 160,
              // Outer Frame (Frosted/Glassy look)
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40), // Increased radius
                color: Colors.white.withValues(
                  alpha: 0.5,
                ), // Thicker/Whiter Frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2), // Outer Glow
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12), // Thicker Frame (12px)
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Inner Radius
                elevation: 4, // Soft lift
                shadowColor: Colors.black.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: _handleAttendanceAction,
                  borderRadius: BorderRadius.circular(
                    30,
                  ), // Also update InkWell's borderRadius
                  child: Container(
                    width: double.infinity,
                    height: double.infinity, // Fill the frame-adjusted space
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 60, color: primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          buttonLabel,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 18, // Scaled up
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusColumn(
                  "Jam Masuk :",
                  _clockInTime,
                  isActive: _clockInTime != "-- : --",
                  isTimeValid: !_isLate,
                  isLocationValid: _checkInLocationValid,
                ),
                _buildStatusColumn(
                  "Jam Keluar :",
                  _clockOutTime,
                  isActive: _clockOutTime != "-- : --",
                  isTimeValid: !_isEarlyLeave,
                  isLocationValid: _checkOutLocationValid,
                ),
              ],
            ),
          ),

          // Glow Bar REMOVED (Moved to Parent Container)
        ],
      ),
    );
  }

  Widget _buildStatusColumn(
    String label,
    String time, {
    required bool isActive,
    bool isTimeValid = true,
    bool isLocationValid = true,
  }) {
    // Determine Icons and Colors
    IconData timeIcon;
    Color timeColor;

    IconData locIcon;
    Color locColor;

    if (!isActive) {
      // Pending State: Neutral White Outline
      timeIcon = Icons.check_circle_outline_rounded;
      timeColor = Colors.white;

      locIcon = Icons.check_circle_outline_rounded;
      locColor = Colors.white;
    } else {
      // Active State: Blue/Red Validation
      timeIcon = isTimeValid
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded;
      timeColor = isTimeValid ? Colors.blueAccent : Colors.redAccent;

      locIcon = isLocationValid
          ? Icons.check_circle_rounded
          : Icons.cancel_rounded;
      locColor = isLocationValid ? Colors.blueAccent : Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Time Section
            const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Icon(timeIcon, color: timeColor, size: 20),

            const SizedBox(width: 12), // Spacing between groups
            // Location Section
            SvgPicture.asset(
              AppIcons.location,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Icon(locIcon, color: locColor, size: 20),
          ],
        ),
      ],
    );
  }
}
