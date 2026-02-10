import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';

import '../../../../../../core/constants/colors.dart'; // Added Import
import '../../../../../../injection_container.dart';
import '../../../domain/repositories/leave_repository.dart';
import '../../../domain/repositories/koreksi_repository.dart';

class CutiDetailVerificationPage extends StatelessWidget {
  final Map<String, String> data;
  final bool isCorrection;

  const CutiDetailVerificationPage({
    super.key,
    required this.data,
    this.isCorrection = false,
  });

  Future<void> _processVerification(
    BuildContext context,
    String status,
    String confirmMessage,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            status == 'DISETUJUI' ? 'Terima Pengajuan' : 'Tolak Pengajuan',
          ),
          content: Text(confirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'DISETUJUI'
                    ? AppColors.primaryBlue
                    : const Color(0xFFFF7043),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!context.mounted) return;
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final int id = int.tryParse(data['id'] ?? '') ?? 0;

        // Call API based on isCorrection
        if (isCorrection) {
          final repo = sl<KoreksiRepository>();
          await repo.approveRequest(id, status);
        } else {
          final repo = sl<LeaveRepository>();
          await repo.approveRequest(id, status);
        }

        // Hide loading
        if (context.mounted) Navigator.pop(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Berhasil ${status == 'DISETUJUI' ? 'menerima' : 'menolak'} pengajuan.",
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Return to list
        }
      } catch (e) {
        // Hide loading
        if (context.mounted) Navigator.pop(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal memproses: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check Status to determine if buttons should be shown
    final bool isPending = (data['status'] ?? 'Menunggu')
        .toUpperCase()
        .contains('MENUNGGU'); // Robust check
    final String fileBukti = data['fileBukti'] ?? '';

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
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.4),
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
                  padding: const EdgeInsets.only(top: 60),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Preview (Only for TL/CP/Luar Radius)
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
                            _buildEvidenceImage(
                              fileBukti,
                              data['startDate'] ?? "-",
                            ),
                            const SizedBox(height: 24),
                          ],

                          _buildInfoSection("Informasi Pegawai", [
                            _buildInfoRow("Nama", data['name'] ?? "-"),
                            _buildInfoRow(
                              "NIP",
                              data['nip'] ?? "-",
                            ), // Fixed Key
                          ]),
                          const SizedBox(height: 20),

                          _buildInfoSection("Detail Izin", [
                            _buildInfoRow("Jenis Cuti", data['type'] ?? "-"),
                            _buildInfoRow(
                              "Tanggal Mulai",
                              data['startDate'] ?? "-",
                            ),
                            _buildInfoRow(
                              "Tanggal Selesai",
                              data['endDate'] ?? "-",
                            ),
                            _buildInfoRow(
                              "Alasan",
                              data['reason'] ?? "-",
                            ), // Added Reason
                            _buildInfoRow("Status", data['status'] ?? "-"),
                          ]),

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
                                      _processVerification(
                                        context,
                                        'DISETUJUI',
                                        'Apakah Anda yakin ingin MENERIMA pengajuan ini?',
                                      );
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
                                      _processVerification(
                                        context,
                                        'DITOLAK',
                                        'Apakah Anda yakin ingin MENOLAK pengajuan ini?',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 40),
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
                Expanded(
                  child: Text(
                    "Verifikasi Cuti Bawahan",
                    style: TextStyle(
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

  Widget _buildEvidenceImage(String? imageUrl, String date) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: (imageUrl != null && imageUrl.isNotEmpty && imageUrl != '-')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "Gagal memuat gambar",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tidak ada bukti lampiran",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(":", style: TextStyle(color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
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
