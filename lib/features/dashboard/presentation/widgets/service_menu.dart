import 'package:flutter/material.dart';
import '../pages/attendance_history/attendance_history_page.dart';
import '../pages/attendance_history/cuti_menu_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceMenu extends ConsumerWidget {
  const ServiceMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch User State
    // final userState = ref.watch(userProvider); // Unused if we only navigate
    // final user = userState.currentUser; // Unused if role is unused
    // actually navigations inside might need context, but not user specifically unless for other logic
    // But let's keep it safe or remove if truly unused.
    // The previous code used 'user' for role check. Since we removed role check, we might not need 'user'
    // BUT, let's keep the imports valid first.

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
                                color: color.withOpacity(0.4),
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
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CutiMenuPage()),
                ),
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
}
