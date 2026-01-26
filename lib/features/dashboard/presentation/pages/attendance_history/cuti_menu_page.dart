import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import 'cuti_history_page.dart';
import 'cuti_verification_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';

class CutiMenuPage extends ConsumerWidget {
  const CutiMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch User State
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final role = user?.role ?? '';

    // Check role
    final bool isAtasan =
        role.isNotEmpty &&
        (role.toLowerCase().contains('admin') ||
            role.toLowerCase().contains('atasan'));
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full Screen Background
          Positioned.fill(
            child: Image.asset(
              'assets/img/balaikotabaru.png',
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
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
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
                        const SizedBox(height: 60),
                        _buildMenuItem(
                          title: "Ajukan Cuti",
                          subtitle: "Ajukan permohonan cuti",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CutiHistoryPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Conditional Verification Menu
                        if (isAtasan)
                          _buildMenuItem(
                            title: "Verifikasi Cuti",
                            subtitle: "Verifikasi permohonan cuti bawahan",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CutiVerificationPage(),
                                ),
                              );
                            },
                          ),
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
          opacity: 0.15,
          blur: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 16),
                Text(
                  "E-Cuti",
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
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA0CBE8), // Light Blue
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Icon (Pencil)
                const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF006064), // Dark Teal Text Color
                  size: 28,
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
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFFB08C00), // Dark Gold/Orange
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB08C00),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
