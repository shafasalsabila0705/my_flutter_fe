import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import 'cuti_application_page.dart';
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
    _refreshHistory();
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
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
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
        backgroundColor: const Color(0xFF0288D1), // Light Blue
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
          opacity: 0.15,
          blur: 15,
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
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada riwayat cuti.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final history = snapshot.data!
            .where((element) => (element.tipe ?? '').toUpperCase() == 'CUTI')
            .toList();

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Name & ID)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Light Grey Header
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.nip ?? "-",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Body (Details)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  "Jenis Cuti",
                  (item.jenisIzin ?? "-").toUpperCase(),
                ),
                const SizedBox(height: 10),
                _buildDetailRow("Tanggal Mulai", item.tanggalMulai ?? "-"),
                const SizedBox(height: 10),
                _buildDetailRow("Tanggal Selesai", item.tanggalSelesai ?? "-"),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 130,
                      child: Text(
                        "Status",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      ": ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          status, // "DITERIMA" e.g.
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const Text(
          ": ",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
