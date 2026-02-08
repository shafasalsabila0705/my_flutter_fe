import 'package:flutter/material.dart';
import '../pages/attendance_history/attendance_history_page.dart';
import '../pages/attendance_history/cuti_menu_page.dart';
import '../pages/attendance_history/cuti_history_page.dart';
import '../../../../../../core/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class ServiceMenu extends ConsumerWidget {
  const ServiceMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch User State
    // final userState = ref.watch(userProvider); // Unused if we only navigate
    // final user = userState.currentUser; // Unused if role is unused
    // actually navigations inside might need context, but not user specifically unless for other logic
    // But let's keep it safe or remove if truly unused.

    void showAboutAppDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.95),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Lottie.asset(
                      'assets/animations/logo_registerlogin.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.app_shortcut_rounded,
                        size: 80,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sistem Absensi Digital ASN Kota Padang",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Versi 2.0.0",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.business_rounded,
                          "Diskominfo Kota",
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.code_rounded, "Tim Pengembang"),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.copyright_rounded,
                          "2026 Hak Cipta Dilindungi",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Tutup"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

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
              GestureDetector(
                onTap: () => showAboutAppDialog(context),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.8),
                ),
              ), // About Button
            ],
          ),
          const SizedBox(height: 20),
          // Service Menu Manual Grid
          Builder(
            builder: (context) {
              Widget buildItem(
                IconData icon,
                String label,
                Color color,
                VoidCallback onTap,
              ) {
                return Expanded(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 24, // Fixed height for text to align rows
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Row 1 Items
              final r1i1 = buildItem(
                Icons.calendar_month_outlined,
                'Presensi',
                const Color(0xFF4FC3F7), // Light Blue
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryPage(),
                  ),
                ),
              );
              final r1i2 = buildItem(
                Icons.flight_takeoff_rounded,
                'e-Cuti',
                const Color(0xFF4FC3F7), // Light Blue
                () {
                  final user = ref.read(userProvider).currentUser;
                  final permissions = user?.permissions ?? [];
                  final role = user?.role ?? '';

                  final isAtasan =
                      permissions.contains('view_team_history') ||
                      (role.isNotEmpty &&
                          (role.toLowerCase().contains('admin') ||
                              role.toLowerCase().contains('atasan')));

                  if (isAtasan) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CutiMenuPage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CutiHistoryPage(),
                      ),
                    );
                  }
                },
              );
              final r1i3 = buildItem(
                Icons.monetization_on_outlined,
                'e-TPP',
                const Color(0xFF4FC3F7), // Light Blue
                () {},
              );
              final r1i4 = buildItem(
                Icons.assignment_outlined,
                'Aktivitas',
                const Color(0xFF4FC3F7), // Light Blue
                () {},
              );
              final r1i5 = buildItem(
                Icons.mail_outline_rounded,
                'Surat',
                const Color(0xFF4FC3F7), // Light Blue
                () {},
              );

              return Column(
                children: [
                  // First Row - Always visible
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      r1i1,
                      const SizedBox(width: 10),
                      r1i2,
                      const SizedBox(width: 10),
                      r1i3,
                      const SizedBox(width: 10),
                      r1i4,
                      const SizedBox(width: 10),
                      r1i5,
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
