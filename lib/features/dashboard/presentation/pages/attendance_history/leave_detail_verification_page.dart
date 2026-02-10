import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/constants/colors.dart'; // Added Import

class LeaveDetailVerificationPage extends StatelessWidget {
  final Map<String, String> data;

  const LeaveDetailVerificationPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Check Status to determine if buttons should be shown
    final bool isPending =
        (data['status'] ?? 'Menunggu').toUpperCase() == 'MENUNGGU';

    // Determine Title
    String title = "Verifikasi Izin Bawahan";
    String type = data['type'] ?? "";
    if (type.contains("Terlambat") ||
        type.contains("Cepat Pulang") ||
        type.contains("TL") ||
        type.contains("CP")) {
      title = "Verifikasi Izin TL/CP";
    } else if (type.contains("LUAR") || type.contains("RADIUS")) {
      title = "Verifikasi Absen Luar Kantor";
    }

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
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.8),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),
                          // Image Placeholder (Only for TL/CP/Luar Radius)
                          if ((data['type'] ?? "").toUpperCase().contains(
                                "TERLAMBAT",
                              ) ||
                              (data['type'] ?? "").toUpperCase().contains(
                                "PULANG",
                              ) ||
                              (data['type'] ?? "").toUpperCase().contains(
                                "RADIUS",
                              ) ||
                              (data['type'] ?? "").toUpperCase().contains(
                                "TL",
                              ) ||
                              (data['type'] ?? "").toUpperCase().contains(
                                "CP",
                              )) ...[
                            _buildImagePlaceholder(data['startDate'] ?? "-"),
                            const SizedBox(height: 24),
                          ],

                          _buildLabel("Nama"),
                          const SizedBox(height: 8),
                          _buildTextField(data['name'] ?? "-"),
                          const SizedBox(height: 16),

                          _buildLabel("NIP"),
                          const SizedBox(height: 8),
                          _buildTextField(data['id'] ?? "-"),
                          const SizedBox(height: 16),

                          _buildLabel("Jenis Izin"),
                          const SizedBox(height: 8),
                          _buildTextField(
                            (data['type'] ?? "-").toUpperCase().replaceAll(
                              '_',
                              ' ',
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Alasan"),
                          const SizedBox(height: 8),
                          _buildTextField(data['reason'] ?? "-"),
                          const SizedBox(height: 40),

                          // Conditional Buttons
                          if (isPending)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    text: "Terima",
                                    color: AppColors.primaryBlue,
                                    onPressed: () {
                                      // Handle Approve
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildActionButton(
                                    text: "Tolak",
                                    color: const Color(
                                      0xFFFF7043,
                                    ), // Red/Orange
                                    onPressed: () {
                                      // Handle Reject
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Header Layer
                Positioned(
                  top: 20,
                  left: 24,
                  right: 24,
                  child: _buildAppBar(context, title),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
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
            child: Row(
              children: [
                const Icon(Icons.arrow_back, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String date) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 250, // Square-ish
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 1),
          ),
          // Placeholder for real image later
        ),
        const SizedBox(height: 8),
        Text(
          date,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
