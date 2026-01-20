import 'package:flutter/material.dart';

class AttendanceActions extends StatefulWidget {
  const AttendanceActions({super.key});

  @override
  State<AttendanceActions> createState() => _AttendanceActionsState();
}

class _AttendanceActionsState extends State<AttendanceActions> {
  @override
  Widget build(BuildContext context) {
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
                  onTap: () {},
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
                        const Icon(
                          Icons.ads_click_rounded,
                          size: 60, // Scaled up
                          color: Color(0xFF29B6F6),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'MASUK',
                          style: TextStyle(
                            color: Color(0xFF29B6F6),
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

          const SizedBox(height: 32),

          // Info Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusColumn("Jam Masuk :"),
                _buildStatusColumn("Jam Keluar :"),
              ],
            ),
          ),

          // Glow Bar REMOVED (Moved to Parent Container)
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String label) {
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
        const Text(
          "-- : --",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 6),
            Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Icon(
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
