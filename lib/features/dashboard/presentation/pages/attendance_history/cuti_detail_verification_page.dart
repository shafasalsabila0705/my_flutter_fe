import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';

import '../../../../../../core/constants/colors.dart'; // Added Import
import '../../../../../../injection_container.dart';
import '../../../domain/repositories/leave_repository.dart';
import '../../../domain/repositories/koreksi_repository.dart';
import '../../../../../../core/network/api_client.dart'; // Added Import
import '../../../domain/entities/request_type.dart'; // Added RequestType import
import '../../../../../../core/utils/date_helper.dart'; // Added Import

class CutiDetailVerificationPage extends StatelessWidget {
  final Map<String, String> data;
  final bool isCorrection;

  const CutiDetailVerificationPage({
    super.key,
    required this.data,
    this.isCorrection = false,
  });

  String _getRequestLabel(String? type) {
    if (type == null) return "Jenis Pengajuan";
    
    // Check for explicit category first
    if (type.toUpperCase() == 'CUTI') return RequestType.cuti.label;
    if (type.toUpperCase() == 'IZIN') return RequestType.izin.label;
    if (type.toUpperCase() == 'KOREKSI') return RequestType.koreksi.label;

    // Fallback to parsing the type string
    return RequestType.fromString(type).label;
  }

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
    final statusStr = (data['status'] ?? 'Menunggu').toUpperCase();
    final bool isPending = statusStr.contains('MENUNGGU');
    final bool isMembatalkan = statusStr.contains('MEMBATALKAN'); // New Status Check

    final String fileBukti = data['fileBukti'] ?? '';

    // ... (Title logic remains same) ...
    
    // Determine Title
    String title = "Detail Pengajuan";
    String category = (data['category'] ?? "").toUpperCase();
    String type = (data['type'] ?? "").toUpperCase();

    if (category == 'CUTI') {
      title = "Verifikasi Cuti Bawahan";
    } else if (category == 'IZIN') {
      title = "Verifikasi Izin Bawahan";
    } else if (category == 'KOREKSI' || category == 'ATTENDANCE') {
      if (type.contains("TERLAMBAT") ||
          type.contains("PULANG") ||
          type.contains("TL") ||
          type.contains("CP")) {
        title = "Verifikasi Izin TL/CP";
      } else if (type.contains("LUAR") || type.contains("RADIUS")) {
        title = "Verifikasi Absen Luar Kantor";
      } else {
        title = "Verifikasi Koreksi Absen";
      }
    } else {
      // Fallback based on type if category is missing or unknown
      if (type.contains("CUTI")) {
        title = "Verifikasi Cuti Bawahan";
      } else if (type.contains("TERLAMBAT") ||
          type.contains("PULANG") ||
          type.contains("TL") ||
          type.contains("CP")) {
        title = "Verifikasi Izin TL/CP";
      } else if (type.contains("LUAR") || type.contains("RADIUS")) {
        title = "Verifikasi Absen Luar Kantor";
      } else {
        title = "Verifikasi Izin Bawahan"; // Default fallback
      }
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
                          if (fileBukti.isNotEmpty &&
                              fileBukti != "-" &&
                              fileBukti.toLowerCase() != "null") ...[
                            _buildEvidenceImage(
                              fileBukti,
                              DateHelper.formatDate(data['startDate']),
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
                            _buildInfoRow(
                              _getRequestLabel(data['category'] ?? data['type']),
                              data['type'] ?? "-",
                            ),
                            _buildInfoRow(
                              "Tanggal Mulai",
                              DateHelper.formatDate(data['startDate']),
                            ),
                            _buildInfoRow(
                              "Tanggal Selesai",
                              DateHelper.formatDate(data['endDate']),
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
                          
                          // Approval Cancel Button
                          if (isMembatalkan)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    text: "Setujui Pembatalan",
                                    color: Colors.red,
                                    onPressed: () {
                                       _processCancellationApproval(context);
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
                  child: _buildAppBar(context, title),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCancellationApproval(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Setujui Pembatalan'),
          content: const Text(
            'Apakah Anda yakin ingin menyetujui pembatalan izin ini? Data izin akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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

        final repo = sl<LeaveRepository>();
        await repo.approveCancelPerizinan(id);

        // Hide loading
        if (context.mounted) Navigator.pop(context);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Berhasil menyetujui pembatalan.",
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

  Widget _buildEvidenceImage(String? imageUrl, String date) {
    final String baseUrl = sl<ApiClient>().dio.options.baseUrl;
    String fullImageUrl = imageUrl ?? "";

    if (fullImageUrl.isNotEmpty &&
        fullImageUrl != '-' &&
        !fullImageUrl.startsWith('http')) {
      final cleanPath = fullImageUrl.startsWith('/')
          ? fullImageUrl.substring(1)
          : fullImageUrl;
      fullImageUrl = '$baseUrl/$cleanPath';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio:
              1, // Change to Square to better accommodate portrait photos
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50, // Light background for letterboxing
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (fullImageUrl.isNotEmpty && fullImageUrl != '-')
                  ? Image.network(
                      fullImageUrl,
                      fit: BoxFit.contain, // Ensure full photo is visible
                      errorBuilder: (ctx, err, stack) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Gagal memuat gambar",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tidak ada bukti lampiran",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
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
