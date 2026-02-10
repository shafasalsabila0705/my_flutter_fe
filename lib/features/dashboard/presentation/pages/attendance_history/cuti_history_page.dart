import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import 'cuti_application_page.dart';
import '../../../../../../core/constants/colors.dart'; // Added Import
import '../../../../../../injection_container.dart';
import '../../../domain/repositories/leave_repository.dart';
import '../../../domain/entities/perizinan.dart';

class CutiHistoryPage extends StatefulWidget {
  const CutiHistoryPage({super.key});

  @override
  State<CutiHistoryPage> createState() => _CutiHistoryPageState();
}

class _CutiHistoryPageState extends State<CutiHistoryPage> {
  late Future<List<Perizinan>> _historyFuture;
  @override
  void initState() {
    super.initState();
    // Initialize immediately to avoid LateInitializationError
    _historyFuture = sl<LeaveRepository>().getLeaveHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = sl<LeaveRepository>().getLeaveHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(child: _buildHistoryList()),
                      ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CutiApplicationPage(),
            ),
          );
          // Refresh if result is true
          if (result == true) {
            _refreshHistory();
          }
        },
        backgroundColor: AppColors.primaryBlue, // Standardized Blue
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
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
                  "Riwayat Cuti",
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

  Widget _buildHistoryList() {
    return FutureBuilder<List<Perizinan>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(
            child: Text(
              "Belum ada riwayat cuti.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Filter first
        final history = snapshot.data!
            .where((element) => (element.tipe ?? '').toUpperCase() == 'CUTI')
            .toList();

        // Check emptiness AFTER filtering
        if (history.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada riwayat cuti.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return _buildHistoryCard(item);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(Perizinan item) {
    Color statusColor = Colors.grey;
    String status = item.status?.toUpperCase() ?? "MENUNGGU";

    if (status.contains("SETUJU")) {
      statusColor = Colors.green;
    } else if (status.contains("TOLAK")) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange; // Menunggu
    }

    // final bool isAtasan =
    //     _currentUser?.permissions.contains('view_team_history') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Role Based
          // Header: Standard for all users (My History)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title Badge (Left)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20), // Capsule
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    (item.jenisIzin ?? "-").toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),

                // Status Badge (Right)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Body: Dates
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCompactRow(
                  Icons.calendar_today_rounded,
                  "Mulai",
                  item.tanggalMulai ?? "-",
                ),
                const SizedBox(height: 12),
                _buildCompactRow(
                  Icons.event_busy_rounded,
                  "Selesai",
                  item.tanggalSelesai ?? "-",
                ),
                if (item.keterangan != null &&
                    item.keterangan!.isNotEmpty &&
                    item.keterangan != '-') ...[
                  const SizedBox(height: 12),
                  _buildCompactRow(
                    Icons.note_alt_outlined,
                    "Alasan",
                    item.keterangan!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(": ", style: TextStyle(color: Colors.grey)),
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
    );
  }
}
