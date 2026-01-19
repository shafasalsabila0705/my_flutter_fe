import 'package:flutter/material.dart';

class AttendanceActions extends StatelessWidget {
  const AttendanceActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Boxy Clock In Button with Glow
          Center(
            child: Container(
              height: 180,
              width: 180, // Fixed width for square/boxy shape
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                // Light outer glow/border
                border: Border.all(
                  color: const Color(0xFF81D4FA).withOpacity(0.3),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF039BE5).withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 5, // Glow effect
                  ),
                ],
              ),
              padding: const EdgeInsets.all(
                8,
              ), // Gap between white border and blue button
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF29B6F6),
                        Color(0xFF0277BD),
                      ], // Top-down gradient
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0277BD).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.touch_app, size: 80, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'CLOCK IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Attendance Info Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFF0288D1),
                width: 1.5,
              ), // Distinct Blue Border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF0288D1),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoItem('Jam Masuk :', '-- : --')),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(child: _buildInfoItem('Jam Keluar :', '-- : --')),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Expanded(child: _buildInfoItem('Jam Kerja :', '-- : --')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
