import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/constants/colors.dart'; // Added Import
import 'leave_history_page.dart'; // Import History Page
import 'leave_verification_page.dart';
import 'attendance_verification_page.dart';
import 'out_of_office_verification_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';

class LeaveMenuPage extends ConsumerWidget {
  const LeaveMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch User State
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final role = user?.role ?? '';

    // Check role based on Atasan/Admin or Permission
    final permissions = user?.permissions ?? [];
    final bool isAtasan =
        permissions.contains('view_team_history') ||
        (role.isNotEmpty &&
            (role.toLowerCase().contains('admin') ||
                role.toLowerCase().contains('atasan')));
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full Screen Background
          Positioned.fill(
            child: Image.asset(
              'assets/img/balai.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF1A1A2E)),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3), // Lighter overlay
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Stack(
              children: [
                // Body Layer (White Container)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 20),
                        _buildMenuItem(
                          title: "Ajukan Izin",
                          subtitle:
                              "Ajukan izin dinas luar, bimtek, atau tubel",
                          icon: Icons.edit_note_rounded,
                          gradientColors: [
                            AppColors.primaryBlue.withValues(alpha: 0.8),
                            AppColors.primaryBlue,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaveHistoryPage(),
                              ),
                            );
                          },
                        ),
                        if (isAtasan) ...[
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            title: "Verifikasi Izin Bawahan",
                            subtitle:
                                "Verifikasi izin dinas luar, bimtek atau tubel bawahan",
                            icon: Icons.fact_check_rounded,
                            gradientColors: [
                              AppColors.primaryBlue.withValues(alpha: 0.8),
                              AppColors.primaryBlue,
                            ],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LeaveVerificationPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          _buildMenuItem(
                            title: "Verifikasi Telat / Cepat Pulang",
                            subtitle: "Verifikasi telat / cepat pulang bawahan",
                            icon: Icons.access_time_filled_rounded,
                            gradientColors: [
                              AppColors.primaryBlue.withValues(alpha: 0.8),
                              AppColors.primaryBlue,
                            ],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AttendanceVerificationPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildMenuItem(
                            title: "Verifikasi Absen Luar Kantor",
                            subtitle: "Verifikasi absen di luar kantor bawahan",
                            icon: Icons.location_on_rounded,
                            gradientColors: [
                              AppColors.primaryBlue.withValues(alpha: 0.8),
                              AppColors.primaryBlue,
                            ],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OutOfOfficeVerificationPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Header Layer (Floating Glass Pill)
                Positioned(
                  top: 20,
                  left: 24,
                  right: 24,
                  child: _buildAppBar(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: GlassCard(
          borderRadius: 30,
          opacity: 0.3,
          blur: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 16),
                Text(
                  "Izin Pegawai",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gradient Icon Container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF2d2d2d),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
