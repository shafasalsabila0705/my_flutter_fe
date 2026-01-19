import 'package:flutter/material.dart';

class ServiceMenu extends StatelessWidget {
  const ServiceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Kepegawaian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Using SingleChildScrollView for horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildServiceItem('Presensi', Icons.calendar_today_outlined),
                const SizedBox(width: 16),
                _buildServiceItem('e-Cuti', Icons.flight_takeoff),
                const SizedBox(width: 16),
                _buildServiceItem('e-TPP', Icons.monetization_on_outlined),
                const SizedBox(width: 16),
                _buildServiceItem('Aktivitas', Icons.assignment_outlined),
                const SizedBox(width: 16),
                _buildServiceItem('Surat Masuk', Icons.mail_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0288D1),
              width: 1.5,
            ), // Match vibrant blue
          ),
          child: Icon(icon, size: 28, color: const Color(0xFF0288D1)),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
