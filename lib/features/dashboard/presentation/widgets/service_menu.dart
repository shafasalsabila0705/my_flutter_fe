import 'package:flutter/material.dart';

class ServiceMenu extends StatelessWidget {
  const ServiceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24,
      ), // Reduced bottom padding (SafeArea handles rest)
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Layanan Kepegawaian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64B5F6),
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: const Color(0xFF64B5F6).withOpacity(0.8),
              ), // About Button
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceItem(
                context,
                Icons.calendar_month_outlined,
                'Presensi',
                () {},
              ),
              _buildServiceItem(
                context,
                Icons.flight_takeoff_rounded,
                'e-Cuti',
                () {},
              ),
              _buildServiceItem(
                context,
                Icons.monetization_on_outlined,
                'e-TPP',
                () {},
              ),
              _buildServiceItem(
                context,
                Icons.assignment_outlined,
                'Aktivitas',
                () {},
              ),
              _buildServiceItem(
                context,
                Icons.mail_outline_rounded,
                'Surat Masuk',
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7), // Light Blue
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Center(child: Icon(icon, color: Colors.white, size: 26)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64B5F6),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
