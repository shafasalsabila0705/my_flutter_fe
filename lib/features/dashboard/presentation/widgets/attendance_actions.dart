import 'package:flutter/material.dart';

import '../../data/models/attendance_model.dart';

class AttendanceActions extends StatefulWidget {
  final Future<AttendanceModel> Function(double lat, double long) onCheckIn;
  final Future<AttendanceModel> Function(double lat, double long) onCheckOut;

  const AttendanceActions({
    super.key,
    required this.onCheckIn,
    required this.onCheckOut,
    this.initialData,
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

          _isLate =
              data.status.toUpperCase().contains('TERLAMBAT') ||
              data.status.toUpperCase().contains('TELAT');
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
                    color: Colors.green.withOpacity(0.1),
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

    final bool isCheckingIn = !_isClockedIn;

    // Check-out Validation for Early Leave
    if (!isCheckingIn) {
      bool isEarly = false;
      final now = DateTime.now();

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
          // Check fallback 16:00 if parse fails
          if (now.hour < 16) isEarly = true;
        }
      } else {
        // Fallback checks if no schedule data
        if (now.hour < 16) isEarly = true;
      }

      if (isEarly) {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
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
                  // Icon Wrapper
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFB300), // Amber Warning Color
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Konfirmasi Pulang Awal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  const Text(
                    "Anda belum berada pada jam pulang.\nApakah Anda yakin ingin pulang sekarang?",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Ya, Pulang",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (confirm != true) return; // User cancelled
      }
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Get real location
      final double lat = 0.0;
      final double long = 0.0;

      AttendanceModel result;

      if (isCheckingIn) {
        result = await widget.onCheckIn(lat, long);
      } else {
        result = await widget.onCheckOut(lat, long);
      }

      if (!mounted) return;

      final String actionLabel = isCheckingIn ? "Masuk" : "Pulang";
      final now = DateTime.now();
      final String formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Determine status logic
      String statusNote = result.status;
      Color statusColor = Colors.green;

      // Logic Variables used for State update later
      bool currentActionIsLate = false;
      bool currentActionIsEarly = false;

      // Handle "Late" Logic (Usually on Check In)
      if (isCheckingIn) {
        currentActionIsLate =
            statusNote.toLowerCase().contains('telat') ||
            statusNote.toLowerCase().contains('terlambat');

        if (currentActionIsLate) {
          statusColor = Colors.red;
        }
      }

      // Handle "Early Leave" Logic (Usually on Check Out)
      if (!isCheckingIn) {
        final bool isEarlyLeaveServer =
            statusNote.toLowerCase().contains('cepat') ||
            statusNote.toLowerCase().contains('awal');

        currentActionIsEarly = isEarlyLeaveServer;

        // Fallback check
        bool isDynamicEarly = false;
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
              isDynamicEarly = true;
            }
          } catch (_) {
            if (now.hour < 16) isDynamicEarly = true;
          }
        } else {
          if (now.hour < 16) isDynamicEarly = true;
        }

        if (isDynamicEarly) {
          currentActionIsEarly = true;
          if (!isEarlyLeaveServer)
            statusNote =
                "PULANG CEPAT"; // Only override if server didn't say it
        }

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
                      color: const Color(0xFF29B6F6).withOpacity(0.1),
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
                          color: statusColor.withOpacity(0.1),
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
          } else {
            // Checking Out
            _isClockedIn = false;
            _clockOutTime = formattedTime;
            _isEarlyLeave = currentActionIsEarly; // Update Early Status
            _isAttendanceComplete = true; // Lock for the day
          }
        });
      });
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      // Ignore silent errors (Holiday Prevention handled by controller dialog)
      if (errorMsg.contains("Holiday Prevention") ||
          errorMsg.contains("Holiday prevention")) {
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
                color: Colors.white.withOpacity(0.5), // Thicker/Whiter Frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2), // Outer Glow
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
                shadowColor: Colors.black.withOpacity(0.1),
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
                        Icon(
                          Icons.ads_click_rounded,
                          size: 60, // Scaled up
                          color: primaryColor,
                        ),
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
                  isNegativeStatus: _isLate,
                  isActive: _clockInTime != "-- : --",
                ),
                _buildStatusColumn(
                  "Jam Keluar :",
                  _clockOutTime,
                  isNegativeStatus: _isEarlyLeave,
                  isActive: _clockOutTime != "-- : --",
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
    bool isNegativeStatus = false,
    bool isActive = false,
  }) {
    // Determine icon and color based on status
    IconData statusIcon = Icons.check_circle_outline_rounded;
    Color statusColor = Colors.white;

    if (isActive) {
      if (isNegativeStatus) {
        statusIcon = Icons.cancel_outlined; // Red Cross
        statusColor = Colors.redAccent;
      } else {
        statusIcon = Icons.check_circle_rounded; // Green Check
        statusColor = Colors.greenAccent;
      }
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
            const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Icon(
              statusIcon,
              color: statusColor,
              size: 20, // Slightly larger for visibility
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ],
    );
  }
}
