import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../../core/constants/colors.dart';
import 'leave_menu_page.dart'; // Import custom page

import '../../../../../../injection_container.dart';
import '../../../domain/repositories/attendance_repository.dart';
import '../../../../auth/domain/repositories/auth_repository.dart'; // Import AuthRepository
import '../../../data/models/attendance_model.dart';
import '../../../domain/entities/perizinan.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/features/dashboard/domain/logic/attendance_statistics_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';
import '../../providers/dashboard_notifier.dart'; // Added import for dashboardProvider
import '../../../../auth/domain/entities/user.dart'; // Explicit import for User
import 'leave_history_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  int _selectedTab = 0; // 0: Saya, 1: Pegawai
  bool _isListView = true; // Toggle between List and Calendar
  late String _selectedMonth; // View init state
  DateTime _focusedDay = DateTime.now();

  bool _isCorrectionAllowed(String? dateStr) {
    if (dateStr == null) return false;
    DateTime targetDate = DateTime.parse(dateStr);
    DateTime now = DateTime.now();

    // Same month: Always allowed
    if (targetDate.year == now.year && targetDate.month == now.month) {
      return true;
    }

    // Previous month: Check deadline (5th working day of current month)
    int monthDiff =
        (now.year - targetDate.year) * 12 + now.month - targetDate.month;
    if (monthDiff == 1) {
      // Calculate 5th working day of this month
      int workingDays = 0;
      int day = 1;
      while (workingDays < 5) {
        DateTime d = DateTime(now.year, now.month, day);
        if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
          workingDays++;
        }
        if (workingDays < 5) day++;
      }
      DateTime deadline = DateTime(now.year, now.month, day, 23, 59, 59);
      return now.isBefore(deadline);
    }

    return false;
  }

  Future<Map<String, dynamic>> _fetchUserAndSupervisorName() async {
    final user = await sl<AuthRepository>().getCurrentUser();
    String supervisorName = user?.atasanNama ?? user?.atasanId ?? "-";

    if (user != null) {
      // Check if name is actually an ID or null, same logic as LeaveApplicationPage
      bool nameIsId = supervisorName == user.atasanId;
      bool nameIsDigit = int.tryParse(supervisorName) != null;

      if (nameIsId ||
          nameIsDigit ||
          supervisorName.isEmpty ||
          supervisorName == "-") {
        try {
          // Fetch remote list to find name
          final supervisors = await sl<AuthRepository>().getAtasanList();
          final supervisor = supervisors.firstWhere(
            (s) => s.id.toString() == user.atasanId.toString(),
            orElse: () => const User(id: '', nip: '', name: '-'),
          );
          if (supervisor.name != '-') {
            supervisorName = supervisor.name;
          }
        } catch (e) {
          debugPrint("Error resolving supervisor name: $e");
        }
      }
    }
    return {'user': user, 'supervisorName': supervisorName};
  }

  void _showLateReasonModal(BuildContext context, String date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CorrectionFormModal(
          fetchUserAndSupervisor: _fetchUserAndSupervisorName,
          date: date,
        );
      },
    );
  }

  final List<String> _months = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  // Data Lists
  List<AttendanceModel> _historyList = [];
  List<Perizinan> _correctionList = [];
  bool _isLoading = true;

  bool _isCorrectionAlreadySubmitted(String? dateStr) {
    if (dateStr == null) return false;
    // Check if there is any correction for this date that is pending or approved
    // Statuses: MENUNGGU VERIFIKASI, DISETUJUI, DITOLAK
    return _correctionList.any((item) {
      // Check for 'KOREKSI' type
      // PerizinanModel sets tipe = 'KOREKSI' in fromCorrectionJson
      if (item.tipe != 'KOREKSI') return false;

      // Parse date
      String? itemDate = item.tanggalMulai;

      if (itemDate == null || itemDate != dateStr) return false;

      // Check status
      // Broaden check: If it contains 'MENUNGGU', 'VERIFIKASI', or 'SETUJU', assume it's active.
      // We only want to allow resubmission if 'DITOLAK' (rejected).
      String status = (item.status ?? '').toUpperCase();
      bool isRejected = status.contains('TOLAK');

      // If NOT rejected, it means it's either Pending or Approved -> Block submission
      return !isRejected;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize to current month
    // Mapping manually to match _months list (Indonesian)
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = _months[currentMonthIndex];

    _fetchHistory();
    _fetchTeamRecap(); // Initial fetch

    // Fetch Bawahan List for Job Titles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadBawahanList();
    });
  }

  // Team Recap Future
  Future<AttendanceRecapModel>? _teamRecapFuture;

  void _fetchTeamRecap() {
    int monthIndex = _months.indexOf(_selectedMonth) + 1;
    final monthStr = monthIndex.toString().padLeft(2, '0');
    final yearStr = DateTime.now().year.toString();

    setState(() {
      // Revert to using getTeamRecap with the new endpoint
      _teamRecapFuture = sl<AttendanceRepository>().getTeamRecap(
        monthStr,
        yearStr,
      );
    });
  }

  List<AttendanceModel> _allHistory = []; // Store source of truth

  Future<void> _fetchHistory() async {
    try {
      final repository = sl<AttendanceRepository>();
      final history = await repository.getHistory();
      final corrections = await repository.getCorrectionHistory(); // Added

      List<AttendanceModel> finalList = List.from(history);

      try {
        final todayMap = await repository.getTodayStatus();
        final status = todayMap['status'];

        if (status != 'BELUM_ABSEN' && todayMap['data'] != null) {
          final todayModel = AttendanceModel.fromJson(todayMap['data']);
          bool exists = finalList.any((e) => e.date == todayModel.date);
          if (!exists) {
            finalList.insert(0, todayModel);
          }
        }
      } catch (e) {
        debugPrint("Error fetching today status: $e");
      }

      setState(() {
        _allHistory = finalList; // Save unfiltered list
        _correctionList = corrections; // Save corrections
        _isLoading = false;
      });
      // Do NOT filter immediately if we want "click Pilih" flow,
      // BUT initially we should probably show something or show empty?
      // User said "pilih bulan, klik pilih, baru muncul".
      // Maybe initially show current month?
      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $e')));
    }
  }

  void _applyFilter() {
    setState(() {
      int monthIndex = _months.indexOf(_selectedMonth) + 1;
      _historyList = _allHistory.where((item) {
        try {
          if (item.date == null) return false;
          final date = DateTime.parse(item.date!);
          // Filter by Month AND Year (assuming current year 2026 based on previous tasks)
          // Ideally user should select year too, but for now we follow the month picker context
          // We'll filter by month only for simplicity as requested, or check year if needed.
          // Let's stick to Month matching for now.
          return date.month == monthIndex;
        } catch (e) {
          return false;
        }
      }).toList();
    });
  }

  // Helper to map color
  Color? _getStatusColor(String status) {
    // Normalize status
    final s = status.toUpperCase();
    if (s.contains('TOLAK')) {
      return const Color(0xFF00BCD4); // Cyan for Rejected
    } else if (s.contains('HADIR') ||
        s.contains('TEPAT WAKTU') ||
        s.contains('BIMTEK') ||
        s.contains('TUBEL') ||
        s.contains('DINAS') ||
        s.contains('LUAR')) {
      return const Color(0xFF009668); // Green for Present & Approved Permits
    } else if (s.contains('IZIN')) {
      return const Color(0xFF00BCD4); // Cyan
    } else if (s.contains('CUTI')) {
      return const Color(0xFF9C27B0); // Purple
    } else if (s.contains('SAKIT')) {
      return const Color(0xFF00BCD4); // Cyan (grouped with Izin)
    } else if (s.contains('TERLAMBAT') ||
        s.contains('PULANG CEPAT') ||
        s.contains('CP')) {
      // Added CP explicitly
      // Check if it's "permitted late" if you have that logic, otherwise Amber
      return const Color(0xFFFFC107); // Amber/Yellow
    } else if (s.contains('ALPA') || s.contains('TANPA')) {
      return const Color(0xFFF44336); // Red
    }
    // Default / Belum Absen
    return const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    // Watch User State here to adjust layout
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final permissions = user?.permissions ?? [];
    final role = user?.role ?? '';

    // Check permission OR role fallback
    final bool isAtasan =
        permissions.contains('view_team_history') ||
        role.toLowerCase().contains('admin') ||
        role.toLowerCase().contains('atasan');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Background handled by Stack
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
                // Pushed down to allow overlap
                Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                        const SizedBox(
                          height: 55,
                        ), // Space for the floating header overlap
                        // Condition Tabs and Spacer
                        if (isAtasan) ...[
                          _buildTabs(),
                          const SizedBox(height: 20),
                        ] else ...[
                          // If not Atasan, maybe a smaller spacer if needed, or none?
                          // The 60px above might be enough or too much.
                          // Let's reduce the top spacer slightly from 60 to 40?
                          // But 60 allows clearing the header.
                          // With no tabs, content starts immediately after header.
                          // Let's keep 60, but removing 20 helps.
                        ],

                        _buildFilterSection(),
                        const SizedBox(height: 20),

                        // Content List or Calendar
                        Expanded(
                          child: _selectedTab == 0
                              ? _buildMyHistoryView()
                              : _buildEmployeeHistoryView(),
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

  // --- Views ---

  Widget _buildMyHistoryView() {
    return Column(
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 10),

        // View Toggle & Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.list_rounded,
                  color: _isListView ? Colors.black87 : Colors.grey,
                ),
                onPressed: () => setState(() => _isListView = true),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: !_isListView ? Colors.black87 : Colors.grey,
                ),
                onPressed: () => setState(() => _isListView = false),
              ),
            ],
          ),
        ),

        // Content List or Calendar
        Expanded(child: _isListView ? _buildListView() : _buildCalendarView()),
      ],
    );
  }

  Widget _buildEmployeeHistoryView() {
    return FutureBuilder<AttendanceRecapModel>(
      future: _teamRecapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Gagal memuat rekap tim: ${snapshot.error}"),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text("Tidak ada data rekap tim."));
        }

        final data = snapshot.data!;

        // Debug
        // debugPrint("Details Data: ${data.details}");

        // --- Client-Side Aggregation Logic (Moved to Helper) ---
        final stats = AttendanceStatisticsHelper.calculate(data);

        // Access via stats object
        int present = stats.present;
        int lateNoPermit = stats.lateNoPermit;
        int latePermitted = stats.latePermitted;
        int permission = stats.permission;
        int leave = stats.leave;
        int unknown = stats.unknown;

        final details = data.details ?? [];

        int presentPercentage = stats.presentPercentage;

        // Colors
        final hadirColor = const Color(0xFF009668); // Green
        final tlColor = const Color(0xFFFFC107); // Amber
        final tlOkColor = const Color(0xFFFF9800); // Orange
        final izinColor = const Color(0xFF00BCD4); // Cyan
        final cutiColor = const Color(0xFF9C27B0); // Purple
        final unknownColor = const Color(0xFFF44336); // Red

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // 1. Chart Section
              const Text(
                "REKAP KEHADIRAN TIM",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Chart
              SizedBox(
                height: 180,
                width: 180,
                child: CustomPaint(
                  painter: DonutChartPainter([
                    ChartData(color: hadirColor, value: present.toDouble()),
                    ChartData(color: tlColor, value: lateNoPermit.toDouble()),
                    ChartData(
                      color: tlOkColor,
                      value: latePermitted.toDouble(),
                    ),
                    ChartData(color: izinColor, value: permission.toDouble()),
                    ChartData(color: cutiColor, value: leave.toDouble()),
                    ChartData(color: unknownColor, value: unknown.toDouble()),
                  ]),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$presentPercentage%",
                            style: const TextStyle(
                              color: Color(0xFF009668),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const Text(
                            "Hadir",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildTeamStatCard(
                      "Hadir Tepat Waktu",
                      "$present",
                      hadirColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTeamStatCard(
                      "TL / CP",
                      "$lateNoPermit",
                      tlColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamStatCard(
                      "TL / CP (Diizinkan)",
                      "$latePermitted",
                      tlOkColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTeamStatCard("Izin", "$permission", izinColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamStatCard("Cuti", "$leave", cutiColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTeamStatCard(
                      "Tanpa Keterangan",
                      "$unknown",
                      unknownColor,
                    ),
                  ),
                ],
              ),

              // 3. Employee List Section
              // Always show if we have subordinates, even if details are empty
              if (true) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Daftar Pegawai",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // List Items from Bawahan List
                Builder(
                  builder: (context) {
                    final bawahanList = ref
                        .watch(dashboardProvider)
                        .bawahanList;

                    // Fallback Logic: Use 'details' if 'bawahanList' is empty
                    // details is List<dynamic> from the recap model
                    var effectiveList = [];
                    bool useBawahanList = false;

                    if (bawahanList.isNotEmpty) {
                      effectiveList = bawahanList;
                      useBawahanList = true;
                    } else if (details.isNotEmpty) {
                      effectiveList = details;
                      useBawahanList = false;
                    }

                    if (effectiveList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            "Belum ada data pegawai.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: effectiveList.map((item) {
                        // Normalize item to User info
                        String name = 'Unknown';
                        String nip = '-';

                        if (useBawahanList && item is User) {
                          name = item.name;
                          nip = item.nip;
                        } else if (item is Map) {
                          name =
                              item['nama'] ??
                              item['name'] ??
                              item['user']?['nama'] ??
                              'Unknown';
                          nip = item['nip']?.toString() ?? '-';
                        }

                        // Stats Logic Removed as per request (Name & NIP only)
                        Color badgeColor = Colors.blueAccent;
                        String rightInfo = nip;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: badgeColor.withValues(
                                  alpha: 0.1,
                                ),
                                radius: 18,
                                child: Icon(
                                  Icons.person,
                                  color: badgeColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rightInfo,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ), // More compact padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08), // Very subtle shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100), // Very light border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label with small dot
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11, // Smaller font
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Value
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Prominent value
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: GlassCard(
              borderRadius: 30,
              opacity: 0.3,
              blur: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white),
                    SizedBox(width: 16),
                    Text(
                      "Riwayat Absensi",
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
        ),
        const SizedBox(width: 10),
        // Leave Menu Button
        GlassCard(
          borderRadius: 20,
          opacity: 0.3,
          blur: 30,
          child: IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: () {
              final user = ref.read(userProvider).currentUser;
              final permissions = user?.permissions ?? [];
              final role = user?.role ?? '';

              final isAtasan =
                  permissions.contains('view_team_history') ||
                  role.toLowerCase().contains('admin') ||
                  role.toLowerCase().contains('atasan');

              if (isAtasan) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveMenuPage(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveHistoryPage(),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    // Watch User State
    // Watch User State
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final permissions = user?.permissions ?? [];
    final role = user?.role ?? '';

    final bool isAtasan =
        permissions.contains('view_team_history') ||
        role.toLowerCase().contains('admin') ||
        role.toLowerCase().contains('atasan');

    if (!isAtasan) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Very light cool grey
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem("Riwayat Saya", 0)),
          Expanded(child: _buildTabItem("Riwayat Pegawai", 1)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        margin: const EdgeInsets.all(4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0288D1) : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pilih Riwayat",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Custom Dropdown Styling
          CustomDropdown<String>(
            value: _selectedMonth,
            items: _months.map((m) {
              return DropdownMenuItem<String>(
                value: m,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primaryBlue.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      m,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedMonth = val!;
                // Sync Calendar
                int monthIndex = _months.indexOf(val) + 1;
                _focusedDay = DateTime(DateTime.now().year, monthIndex, 1);
              });
              _applyFilter(); // Auto-refresh logic
              _fetchTeamRecap(); // Refresh team data
            },
            hint: "Pilih Bulan",
            prefixIcon: null, // Icons inside items now
          ),
        ],
      ),
    );
  }

  int _getWorkingDaysInMonth(int year, int month) {
    int days = 0;
    // Get last day of month
    int daysInMonth = DateTime(year, month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      DateTime date = DateTime(year, month, i);
      // Monday (1) to Friday (5) are working days
      if (date.weekday >= 1 && date.weekday <= 5) {
        days++;
      }
    }
    return days;
  }

  Widget _buildSummaryCards() {
    // Map back to the 3-card summary format using the detailed stats
    // Hari Kerja: Hadir + TL/CP (All)
    // Terlambat: Duration (needs original _calculateSummaryData logic or just re-implement duration calc here?)
    // Actually, let's keep _calculateDetailedStats for the COUNTS,
    // but we might need the original duration logic for "Terlambat" and "Jam Kerja" cards.
    // Let's re-add the duration logic into a helper or just Inline it back into _calculateSummaryData
    // BUT the user wants the 7-color breakdown.
    // Wait, the user said "tampilan nya kaya yang tadi aja" (like before), "tapi yang tadi itu warna nya kurang 1" (but missing 1 color).
    // The "tadi" (before) view had:
    // 1. Summary Cards (Hari Kerja, Terlambat, Jam Kerja)
    // 2. Legend (6 items)
    // The user wants THAT view, but with 7 items in Legend.

    // So I need to:
    // 1. Restore _calculateSummaryData (for the cards)
    // 2. Restore _buildSummaryCards (using _calculateSummaryData)
    // 3. Restore _buildLegend (with 7 items)
    // 4. Remove _buildPersonalStatistics

    // Let's first re-implement _calculateSummaryData (Duration based)
    int presentCount = 0;
    int totalLateMinutes = 0;
    int totalWorkMinutes = 0;
    int workDaysCount = 0;

    int currentYear = DateTime.now().year;
    int currentMonthIndex = _months.indexOf(_selectedMonth) + 1;
    int totalWorkingDays = _getWorkingDaysInMonth(
      currentYear,
      currentMonthIndex,
    );

    for (var item in _historyList) {
      final status = (item.status).toUpperCase();
      if (status.contains('HADIR') ||
          status.contains('TEPAT') ||
          status.contains('TERLAMBAT') ||
          status.contains('PULANG') ||
          status.contains('CP')) {
        presentCount++;
      }

      // Parsing logic
      DateTime? parseTime(String? timeStr) {
        if (timeStr == null || timeStr == '-' || timeStr.isEmpty) return null;
        try {
          final parts = timeStr.split(':');
          final now = DateTime.now();
          return DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
            parts.length > 2 ? int.parse(parts[2]) : 0,
          );
        } catch (e) {
          return null;
        }
      }

      final checkIn = parseTime(item.checkInTime);
      final checkOut = parseTime(item.checkOutTime);
      final scheduledIn = parseTime(item.scheduledCheckInTime ?? "08:00:00");
      final scheduledOut = parseTime(item.scheduledCheckOutTime ?? "16:00:00");

      if (checkIn != null &&
          scheduledIn != null &&
          checkIn.isAfter(scheduledIn)) {
        totalLateMinutes += checkIn.difference(scheduledIn).inMinutes;
      }
      if (checkOut != null &&
          scheduledOut != null &&
          checkOut.isBefore(scheduledOut)) {
        totalLateMinutes += scheduledOut.difference(checkOut).inMinutes;
      }
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn).inMinutes;
        if (duration > 0) {
          totalWorkMinutes += duration;
          workDaysCount++;
        }
      }
    }

    String formatDuration(int minutes) {
      if (minutes == 0) return "0 menit";
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h > 0 && m > 0) return "$h jam $m menit";
      if (h > 0) return "$h jam";
      return "$m menit";
    }

    int avgWorkMinutes = workDaysCount > 0
        ? (totalWorkMinutes / workDaysCount).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              "Hari Kerja",
              "$presentCount/$totalWorkingDays hari",
              const Color(0xFF66BB6A),
              Icons.calendar_today,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCard(
              "Terlambat",
              formatDuration(totalLateMinutes),
              const Color(0xFFFFC107), // Amber for Late
              Icons.assignment_late_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCard(
              "Jam Kerja (Rata2)",
              formatDuration(avgWorkMinutes),
              const Color(0xFF0288D1),
              Icons.work_outline,
            ),
          ),
        ],
      ),
    );
  }

  // Restore Legend with 6 Items (Removed Belum Absen)
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem("Hadir", const Color(0xFF009668)),
          _buildLegendItem("TL / CP", const Color(0xFFFFC107)),
          _buildLegendItem(
            "TL / CP (Diizinkan)",
            const Color(0xFFFF9800),
          ), // Orange
          _buildLegendItem("Izin", const Color(0xFF00BCD4)),
          _buildLegendItem("Cuti", const Color(0xFF9C27B0)),
          _buildLegendItem("Tanpa Ket.", const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historyList.isEmpty) {
      return const Center(child: Text("Belum ada riwayat absensi"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[index];
        final color = _getStatusColor(item.status) ?? Colors.grey;

        // Parse date (Assuming 'YYYY-MM-DD' from API to 'dd' and 'MMM')
        // Or using formatted string from API if available.
        // Logic: if date is "2026-01-22", day is "22", month is "JAN".
        String dateStr = item.date ?? "";
        String dayNum = "";
        String monthStr = "";
        String dayName = "";

        try {
          if (dateStr.isNotEmpty) {
            DateTime dt = DateTime.parse(dateStr);
            dayNum = DateFormat('dd').format(dt);
            monthStr = DateFormat('MMM').format(dt).toUpperCase();
            dayName = DateFormat(
              'EEEE',
              'id_ID',
            ).format(dt); // Requires setting locale
          }
        } catch (_) {
          dayNum = dateStr; // Fallback
        }

        // Time logic: "08.00 - 16.00" or "08.00 - (-)"
        String checkIn = item.checkInTime;
        String checkOut = item.checkOutTime ?? "(-)";
        if (checkOut.isEmpty || checkOut == "-") checkOut = "(-)";
        String timeDisplay = "$checkIn - $checkOut";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: () {
              final s = item.status.toUpperCase();
              if (s.contains('TERLAMBAT') ||
                  s.contains('PULANG CEPAT') ||
                  s.contains('CP')) {
                if (_isCorrectionAlreadySubmitted(item.date)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Izin TL/CP sudah diajukan"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (_isCorrectionAllowed(item.date)) {
                  _showLateReasonModal(context, item.date ?? "");
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Batas pengajuan TL/CP (Minggu pertama bulan berikutnya) sudah berakhir.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Colored Strip & Date
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1), // Light bg
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicator Line
                Container(width: 4, height: 60, color: color),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName.isNotEmpty ? dayName : (item.date ?? "-"),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Customized Display Logic
                      Builder(
                        builder: (context) {
                          String displayStatus = item.status;
                          final s = item.status.toUpperCase();
                          if ((s.contains('BIMTEK') ||
                                  s.contains('TUBEL') ||
                                  s.contains('DINAS') ||
                                  s.contains('LUAR')) &&
                              !s.contains('TOLAK') &&
                              !s.contains('MENUNGGU')) {
                            displayStatus = "HADIR (${item.status})";
                          }
                          return Text(
                            displayStatus,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeDisplay,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    // 1. Calculate month details
    final int year = _focusedDay.year;
    final int month = _focusedDay.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final DateTime firstDayOfMonth = DateTime(year, month, 1);

    // Weekday: Mon=1 ... Sun=7.
    // If we want Sun to be first column (index 0):
    // Sunday(7) -> 0, Monday(1) -> 1 ... Saturday(6) -> 6.
    final int firstWeekdayOffset = firstDayOfMonth.weekday % 7;

    // Previous month details for filling gaps
    final DateTime prevMonthDate = DateTime(year, month - 1, 1);
    final int daysInPrevMonth = DateUtils.getDaysInMonth(
      prevMonthDate.year,
      prevMonthDate.month,
    );

    final String monthName = _months[month - 1]; // 0-indexed

    return Column(
      children: [
        // Month Nav
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(year, month - 1, 1);
                  // Sync Dropdown
                  _selectedMonth = _months[_focusedDay.month - 1];
                });
                _applyFilter();
                _fetchTeamRecap();
              },
            ),
            Text(
              "$monthName $year",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(year, month + 1, 1);
                  // Sync Dropdown
                  _selectedMonth = _months[_focusedDay.month - 1];
                });
                _applyFilter();
                _fetchTeamRecap();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Weekday Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
              .map(
                (d) => Text(
                  d,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (d == "Min" || d == "Sab")
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            // 6 rows * 7 cols = 42 cells to cover all possibilities
            itemCount: 42,
            itemBuilder: (context, index) {
              int day;
              bool isCurrentMonth = true;
              DateTime cellDate;

              if (index < firstWeekdayOffset) {
                // Previous month
                isCurrentMonth = false;
                day = daysInPrevMonth - (firstWeekdayOffset - index) + 1;
                cellDate = DateTime(year, month - 1, day);
              } else if (index >= firstWeekdayOffset + daysInMonth) {
                // Next month
                isCurrentMonth = false;
                day = index - (firstWeekdayOffset + daysInMonth) + 1;
                cellDate = DateTime(year, month + 1, day);
              } else {
                // Current month
                day = index - firstWeekdayOffset + 1;
                cellDate = DateTime(year, month, day);
              }

              // Check status from _historyList
              // We need to match cellDate (YYYY-MM-DD) with item.date
              AttendanceModel? dailyData;
              try {
                final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
                dailyData = _historyList.firstWhere((e) => e.date == dateKey);
              } catch (_) {
                dailyData = null;
              }

              Color? statusColor;
              if (isCurrentMonth && dailyData != null) {
                statusColor = _getStatusColor(dailyData.status);
              }

              // Highlight today if needed?
              // For now just status.

              return GestureDetector(
                onTap: () {
                  if (isCurrentMonth && dailyData != null) {
                    final s = dailyData.status.toUpperCase();
                    if (s.contains('TERLAMBAT') ||
                        s.contains('PULANG CEPAT') ||
                        s.contains('CP')) {
                      if (_isCorrectionAlreadySubmitted(dailyData.date)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Izin TL/CP sudah diajukan"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else if (_isCorrectionAllowed(dailyData.date)) {
                        _showLateReasonModal(context, dailyData.date ?? "");
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Batas pengajuan TL/CP (Minggu pertama bulan berikutnya) sudah berakhir.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (statusColor != null)
                          ? statusColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCurrentMonth ? "$day" : "",
                          style: TextStyle(
                            color: isCurrentMonth
                                ? (statusColor != null
                                      ? Colors.white
                                      : (cellDate.weekday ==
                                                DateTime.saturday ||
                                            cellDate.weekday == DateTime.sunday)
                                      ? Colors.red
                                      : Colors.black)
                                : Colors.transparent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCurrentMonth &&
                            DateTime.now().year == cellDate.year &&
                            DateTime.now().month == cellDate.month &&
                            DateTime.now().day == cellDate.day)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ChartData {
  final Color color;
  final double value;
  ChartData({required this.color, required this.value});
}

class DonutChartPainter extends CustomPainter {
  final List<ChartData> data;
  DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 20.0;

    // Draw background circle
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    double startAngle = -3.14 / 2; // Start from top (-90 deg)

    // Calculate total for percentage
    final total = data.fold(0.0, (sum, item) => sum + item.value);

    for (var item in data) {
      final sweepAngle = (item.value / total) * 2 * 3.14;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw Arc
      // Need rect for arc
      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );

      // Use drawArc with gap? Design shows gaps.
      // Simple implementation:
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle - 0.1,
        false,
        paint,
      ); // -0.1 for small gap

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CorrectionFormModal extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() fetchUserAndSupervisor;
  final String date;

  const CorrectionFormModal({
    super.key,
    required this.fetchUserAndSupervisor,
    required this.date,
  });

  @override
  State<CorrectionFormModal> createState() => _CorrectionFormModalState();
}

class _CorrectionFormModalState extends State<CorrectionFormModal> {
  late Future<Map<String, dynamic>> _dataFuture;
  final TextEditingController _alasanController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = widget.fetchUserAndSupervisor();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_alasanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alasan wajib diisi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await sl<AttendanceRepository>().submitCorrection(
        tanggal: widget.date,
        alasan: _alasanController.text,
        bukti: _selectedFile,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengajuan TL/CP berhasil dikirim"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        final String atasanNama = data?['supervisorName'] ?? '-';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Atasan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: atasanNama),
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Alasan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _alasanController,
                maxLines: 2,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: _selectedFile != null
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.check_circle_outline
                            : Icons.file_upload_outlined,
                        color: _selectedFile != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile != null
                              ? "Bukti Terlampir: ${_selectedFile!.path.split('/').last}"
                              : "Lampirkan Bukti (Foto/Dokumen)",
                          style: TextStyle(
                            color: _selectedFile != null
                                ? Colors.green
                                : Colors.grey,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_selectedFile != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFile = null;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Simpan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
