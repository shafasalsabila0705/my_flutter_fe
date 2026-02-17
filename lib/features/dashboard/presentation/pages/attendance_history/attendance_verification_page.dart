import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../injection_container.dart';
import '../../../domain/repositories/koreksi_repository.dart';
import '../../../domain/entities/perizinan.dart';
import '../../../data/models/perizinan_model.dart';
import 'cuti_detail_verification_page.dart';
import '../../../../../../core/utils/status_helper.dart';
import '../../../../../../core/utils/date_helper.dart'; // Added Import

class AttendanceVerificationPage extends StatefulWidget {
  const AttendanceVerificationPage({super.key});

  @override
  State<AttendanceVerificationPage> createState() =>
      _AttendanceVerificationPageState();
}

class _AttendanceVerificationPageState
    extends State<AttendanceVerificationPage> {
  String _selectedFilter = "Semua";
  final List<String> _filters = ["Semua", "Menunggu", "Diterima", "Ditolak"];
  late Future<List<Perizinan>> _verificationFuture;

  @override
  void initState() {
    super.initState();
    _refreshVerification();
  }

  void _refreshVerification() {
    setState(() {
      // Use KoreksiRepository for Attendance Issues (Late/Early)
      _verificationFuture = sl<KoreksiRepository>()
          .getSubordinateRequests()
          .then((koreksiList) {
            return koreksiList.map((k) {
              return PerizinanModel.fromCorrectionJson(k.toJson());
            }).toList();
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Background
          Positioned.fill(
            child: Image.asset(
              'assets/img/balai.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF1A1A2E)),
            ),
          ),
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
                        _buildFilterTabs(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _refreshVerification();
                            },
                            child: _buildVerificationList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                  "Verifikasi Telat / Cepat Pulang",
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

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFC107)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerificationList() {
    return FutureBuilder<List<Perizinan>>(
      future: _verificationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada pengajuan."));
        }

        // FILTER LOGIC - SPECIFIC FOR LATE/EARLY (TL/CP)
        final filteredList = snapshot.data!.where((item) {
          // 1. Filter by Type
          final jenis = (item.jenisIzin ?? '').toUpperCase();

          // "TERLAMBAT", "PULANG_CEPAT", "KOREKSI"
          bool isAttendanceIssue =
              (jenis.contains('TERLAMBAT') ||
                  jenis.contains('TELAT') ||
                  jenis.contains('CEPAT') ||
                  jenis.contains('PULANG') ||
                  jenis == 'KOREKSI') &&
              !(jenis.contains('LUAR') || jenis.contains('RADIUS'));

          if (!isAttendanceIssue) return false;

          // 2. Filter by Status Tab
          if (_selectedFilter == "Semua") return true;

          final status = StatusHelper.mapStatusToIndonesian(item.status);

          if (_selectedFilter == "Menunggu") {
            return status == "MENUNGGU";
          }
          if (_selectedFilter == "Diterima") {
            return status == "DISETUJUI";
          }
          if (_selectedFilter == "Ditolak") {
            return status == "DITOLAK";
          }

          return true;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(child: Text("Tidak ada data sesuai filter."));
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return _buildRequestCard(item);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Perizinan item) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CutiDetailVerificationPage(
              isCorrection: true,
              data: {
                "id": item.id ?? "",
                "name": item.name ?? "-",
                "nip": item.nip ?? "-",
                "type": item.jenisIzin ?? "-",
                "startDate": item.tanggalMulai ?? "-",
                "endDate": item.tanggalSelesai ?? "-",
                "status": item.status ?? "-",
                "reason": item.keterangan ?? "-",
                "fileBukti": item.fileBukti ?? "",
                "category": "KOREKSI",
              },
            ),
          ),
        );
        _refreshVerification();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
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
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    "Jenis",
                    (item.jenisIzin ?? "-").toUpperCase().replaceAll('_', ' '),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow("Tanggal", DateHelper.formatDate(item.tanggalMulai)),
                  // For attendance corrections, Start/End are usually same day
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    "Keterangan",
                    StatusHelper.mapStatusToIndonesian(item.status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
