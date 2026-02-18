import '../../../../../../core/services/location_service.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../../core/constants/colors.dart';
import 'leave_menu_page.dart'; // Import custom page

import '../../../../../../injection_container.dart';
import '../../../data/datasources/attendance_remote_data_source.dart';
import '../../../domain/repositories/attendance_repository.dart';
import '../../../../auth/domain/repositories/auth_repository.dart'; // Import AuthRepository
import '../../../data/models/attendance_model.dart';
import '../../../data/models/schedule_item_model.dart'; // Ensure this is present
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
  List<HistoryDayItem> _historyList = []; // REFACTORED: Now uses HistoryDayItem
  List<AttendanceModel> _rawHistory = []; // Store raw for other uses if needed
  List<Perizinan> _correctionList = [];
  AttendanceRecapModel? _summaryRecap; // Added this missing variable
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

  List<HistoryDayItem> _allHistory = []; // Store source of truth

  Future<void> _fetchHistory() async {
    try {
      final repository = sl<AttendanceRepository>();
      
      // Calculate Month/Year from _focusedDay (which syncs with dropdown)
      final String monthStr = _focusedDay.month.toString().padLeft(2, '0');
      final String yearStr = _focusedDay.year.toString();

      // Parallel execution
      final results = await Future.wait([
        repository.getHistory(),
        repository.getCorrectionHistory(),
        repository.getTodayStatus().catchError((e) {
            debugPrint("Error fetching today status: $e");
            return <String, dynamic>{}; 
        }),
        repository.getRecap(monthStr, yearStr).catchError((e) {
            debugPrint("Error fetching recap for summary: $e");
             return const AttendanceRecapModel(
              present: 0, late: 0, permission: 0, leave: 0, 
              alpha: 0, lateAllowed: 0, notPresent: 0, details: []
            );
        }),
        repository.getMonthlySchedule(monthStr, yearStr).catchError((e) {
            debugPrint("Error fetching monthly schedule: $e");
            return <ScheduleItemModel>[];
        }),
      ]);

      final history = results[0] as List<AttendanceModel>;
      final corrections = results[1] as List<Perizinan>;
      final todayMap = results[2] as Map<String, dynamic>;
      final recap = results[3] as AttendanceRecapModel; 
      final scheduleList = results[4] as List<ScheduleItemModel>;

      List<AttendanceModel> attendanceList = List.from(history);

      try {
        final status = todayMap['status'];
        if (status != 'BELUM_ABSEN' && todayMap['data'] != null) {
          final todayModel = AttendanceModel.fromJson(todayMap['data']);
          bool exists = attendanceList.any((e) => e.date == todayModel.date);
          if (!exists) {
            attendanceList.insert(0, todayModel);
          }
        }
      } catch (e) {
        debugPrint("Error fetching today status: $e");
      }

      // Process Data into HistoryDayItems using Schedule List (API) + Attendance
      // Calculate month/year from _focusedDay as it syncs with selection
      final processedItems = _processHistoryData(attendanceList, scheduleList, _focusedDay.month, _focusedDay.year);

      setState(() {
        _rawHistory = attendanceList; // Save raw attendance data
        _allHistory = processedItems; // Save processed list (Schedule based)
        _correctionList = corrections;
        _summaryRecap = recap;
        _isLoading = false;
      });
      
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

  // --- DATA TRANSFORMATION LOGIC ---
  List<HistoryDayItem> _processHistoryData(
      List<AttendanceModel> attendanceData, List<ScheduleItemModel> scheduleList, int month, int year) {
    
    int daysInMonth = DateUtils.getDaysInMonth(year, month);
    List<HistoryDayItem> processedList = [];

    for (int i = 1; i <= daysInMonth; i++) {
      String paramsDate = "$year-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
      DateTime currentDate = DateTime(year, month, i);

      // 1. Find Schedule
      ScheduleItemModel? scheduleItem;
      try {
        scheduleItem = scheduleList.firstWhere(
          (s) => s.date == paramsDate, 
          orElse: () => ScheduleItemModel(date: '', id: -1), 
        );
        if (scheduleItem.id == -1) scheduleItem = null;
      } catch (_) {}

      ScheduleModel? schedule;
      bool isHoliday = false;

      if (scheduleItem != null) {
         String scheduleStatus = (scheduleItem.status ?? '').toUpperCase();
         if (scheduleStatus == 'LIBUR' || scheduleItem.shiftName == 'LIBUR') {
           isHoliday = true;
         }
         
         // In new API, jam_masuk_shift is defined
         schedule = ScheduleModel(
           startTime: scheduleItem.shiftStart,
           endTime: scheduleItem.shiftEnd,
           isHoliday: isHoliday,
           // Add name if needed? 
         );
      }

      // 2. Find Attendance
      AttendanceModel? match;
      try {
        match = attendanceData.firstWhere((a) => a.date == paramsDate);
      } catch (_) {}

      // 3. Determine Status
      String status = "-"; 
      if (match != null) {
        status = match.status;
      } else if (isHoliday) {
        status = "LIBUR";
      } else {
        if (schedule != null && !isHoliday) {
           status = "BELUM ABSEN";
        } else {
           status = "-";
        }
      }

      processedList.add(HistoryDayItem(
        date: currentDate,
        rawDate: paramsDate,
        schedule: schedule,
        attendance: match,
        status: status,
      ));
    }

    // Sort Ascending (1 to 31)
    return processedList;
  }

  void _applyFilter() {
    setState(() {
      int monthIndex = _months.indexOf(_selectedMonth) + 1;
      _historyList = _allHistory.where((item) {
        try {
          // Date is already parsed in HistoryDayItem
          return item.date.month == monthIndex;
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
    } else if (s.contains('LIBUR')) {
      return const Color(0xFFE53935); // Red for Holiday
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
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await _fetchHistory();
                              _fetchTeamRecap();
                            },
                            child: _selectedTab == 0
                                ? _buildMyHistoryView()
                                : _buildEmployeeHistoryView(),
                          ),
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
        int notPresent = stats.notPresent;

        final details = data.details ?? [];

        int presentPercentage = stats.presentPercentage;

        // Colors
        final hadirColor = const Color(0xFF009668); // Green
        final tlColor = const Color(0xFFFFC107); // Amber
        final tlOkColor = const Color(0xFFFF9800); // Orange
        final izinColor = const Color(0xFF00BCD4); // Cyan
        final cutiColor = const Color(0xFF9C27B0); // Purple
        final unknownColor = const Color(0xFFF44336); // Red
        final notPresentColor = const Color(0xFF9E9E9E); // Grey

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
                    ChartData(
                      color: notPresentColor,
                      value: notPresent.toDouble(),
                    ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamStatCard(
                      "Belum Absen",
                      "$notPresent",
                      notPresentColor,
                    ),
                  ),
                  const Spacer(), // Keeps layout consistent
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

    // Calculate Total Working Days from Backend Schedule
    // Count items that have a schedule and are NOT holidays
    int totalWorkingDays = _historyList.where((item) => 
        item.schedule != null && !item.schedule!.isHoliday
    ).length;

    // Fallback if schedule is empty (e.g. error or first load), use dynamic calculation ??
    // Actually, if schedule is empty, totalWorkingDays will be 0, which might be confusing.
    // But since we rely on backend, 0 is technically the "backend truth" if it returns empty.
    // However, to be safe during transition or error, we can keep the old method as fallback IF count is 0.
    if (totalWorkingDays == 0) {
      int currentYear = _focusedDay.year;
      int currentMonthIndex = _focusedDay.month;
       totalWorkingDays = _getWorkingDaysInMonth(
        currentYear,
        currentMonthIndex,
      );
    }

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

      final checkIn = parseTime(item.attendance?.checkInTime);
      final checkOut = parseTime(item.attendance?.checkOutTime);
      
      // Use schedule model if available, otherwise fallback to attendance or default
      String defIn = "08:00:00";
      String defOut = "16:00:00";
      
      if (item.schedule != null) {
        defIn = item.schedule!.startTime ?? defIn;
        defOut = item.schedule!.endTime ?? defOut;
      } else if (item.attendance != null) {
        defIn = item.attendance!.scheduledCheckInTime ?? defIn;
        defOut = item.attendance!.scheduledCheckOutTime ?? defOut;
      }

      final scheduledIn = parseTime(defIn);
      final scheduledOut = parseTime(defOut);

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

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: const [
              SizedBox(width: 70, child: Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), // Widen for single line
              Expanded(child: Center(child: Text("Waktu / Keterangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              SizedBox(width: 60, child: Center(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
        
        // List Items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _historyList.length,
            itemBuilder: (context, index) {
              final item = _historyList[index];
              final date = item.date;
              final dayNum = DateFormat('dd').format(date);
              final dayName = DateFormat('EEEE', 'id_ID').format(date);
              final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
              
              // Determine logic
              bool isHoliday = item.schedule?.isHoliday ?? false;
              bool isWorkingDay = false;
              if (item.schedule != null) {
                isWorkingDay = !item.schedule!.isHoliday;
              }

              // Background Color Logic
              // User: "setiap ngga ada jadwal dikasih tanda merah saja" -> Red mark for no schedule
              // User: "kalau ada jadwal ... warna harinya itu putihh"
              
              Color bgColor = Colors.white;
              if (item.schedule != null) {
                // Has Schedule -> White (even if Holiday? User said "kalau ada jadwal... putih")
                // Usually holidays are in schedule but marked as holiday.
                if (item.schedule!.isHoliday) {
                   bgColor = Colors.white; // Or maybe keep grey? Let's stick to "ada jadwal -> putih"
                } else {
                   bgColor = Colors.white; 
                }
              } else {
                // No Schedule -> Red Mark
                // Using a very light red/pink background to indicate "Tanda Merah"
                bgColor = const Color(0xFFFFEBEE); // Red.shade50
              }

              // Middle Content Logic
              String middleText = "-";
              if (isHoliday) {
                middleText = "Libur Nasional / Cuti Bersama"; // Or use item.schedule?.shiftName if it contains holiday name?
              } else if (!isWorkingDay) {
                middleText = dayName; // "Sabtu", "Minggu" etc.
              } else {
                // Working Day
                if (item.attendance != null && (item.attendance?.checkInTime != null || item.attendance?.checkOutTime != null)) {
                   // Show Attendance Time
                   String checkIn = item.attendance?.checkInTime ?? "-";
                   String checkOut = item.attendance?.checkOutTime ?? "-";
                   if (checkOut == "") checkOut = "-";
                   
                   if (checkIn != "-" && checkOut == "-") {
                      middleText = "$checkIn - ";
                   } else if (checkIn == "-" && checkOut == "-") {
                      middleText = "-";
                   } else {
                      middleText = "$checkIn - $checkOut";
                   }
                } else {
                   // Scheduled but Not Absent -> "-"
                   middleText = "-";
                }
              }

              // Status Logic & Color (No change needed here, just contextual)
              String statusText = "";
              Color statusColor = Colors.transparent;
              String rawStatus = (item.status).toUpperCase();

              if (rawStatus.contains("TERLAMBAT") || rawStatus.contains("TL")) {
                 statusText = "TL";
                 statusColor = const Color(0xFFFFC107); // Yellow
              } else if (rawStatus.contains("PULANG CEPAT") || rawStatus.contains("CP")) {
                 statusText = "CP";
                 statusColor = const Color(0xFFFFC107); // Yellow (Group with late as per request usually)
              } else if (rawStatus.contains("CUTI")) {
                 statusText = "CUTI";
                 statusColor = const Color(0xFF9C27B0); // Purple
              } else if (rawStatus.contains("IZIN")) {
                 statusText = "IZIN";
                 statusColor = const Color(0xFF009688); // Teal (Tosca)
              } else if (rawStatus.contains("TO") || rawStatus.contains("ALPHA") || rawStatus.contains("TANPA") || rawStatus.contains("BELUM")) {
                 // Only show 'TK' or 'A' if it's a working day and passed
                 if (isWorkingDay && date.isBefore(DateTime.now())) {
                    statusText = "TK";
                    statusColor = Colors.red;
                 }
              } else if (rawStatus.contains("HADIR") || rawStatus.contains("TEPAT")) {
                  // statusText = "H"; // Optional: User didn't specify color for Hadir list, implies maybe empty or standard?
                  // Image shows empty for normal days, but let's show 'H' or check icon?
                  // User Request: "jika keterangannya terlambat... cuti... izin... tanpa keterangan..."
                  // Implies only abnormal statuses needs highlighting?
                  // Let's leave empty if Hadir Tepat Waktu to be clean like image (rows 5,6,7 in image example have times but no status text).
                  statusText = ""; 
              }

              // Override Middle Text for Belum Absen on working day
              if (middleText == "-" && isWorkingDay && date.isBefore(DateTime.now())) {
                 // Keep "-" or show "Belum Absen"? Image shows "-"
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    // Date
                    SizedBox(
                      width: 70, 
                      child: Text(
                        dayNum, 
                        style: TextStyle(
                          color: (isHoliday) ? Colors.red : Colors.grey.shade700,
                          fontWeight: FontWeight.w500
                        )
                      )
                    ),
                    // Content
                    Expanded(
                      child: Center(
                        child: Text(
                          middleText,
                          style: TextStyle(
                            color: (isHoliday) ? Colors.red : Colors.grey.shade800,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Status
                    SizedBox(
                      width: 60,
                      child: Center(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                    color: Colors.black87,
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
              HistoryDayItem? dailyData;
              try {
                dailyData = _historyList.firstWhere((e) => 
                  e.date.year == cellDate.year &&
                  e.date.month == cellDate.month &&
                  e.date.day == cellDate.day
                );
              } catch (_) {
                dailyData = null;
              }

              // Color Logic
              Color? cellColor = Colors.transparent;
              Color textColor = Colors.black87;

              if (isCurrentMonth) {
                // Default Text Color: Black for Weekdays
                // if (cellDate.weekday == DateTime.saturday || cellDate.weekday == DateTime.sunday) {
                //   textColor = Colors.red;
                // }

                if (dailyData != null) {
                  // 1. Background Logic (No Schedule -> Red Tint)
                  bool hasSchedule = dailyData.schedule != null;
                  
                  if (!hasSchedule) {
                    cellColor = const Color(0xFFFFEBEE); // Red shade 50
                  } 
                  
                  // 2. Status Logic (Overrides Background)
                  String status = dailyData.status.toUpperCase();
                  if (status.contains("TERLAMBAT") || status.contains("TL")) {
                     cellColor = const Color(0xFFFFC107); // Amber
                     textColor = Colors.white;
                  } else if (status.contains("PULANG CEPAT") || status.contains("CP")) {
                     cellColor = const Color(0xFFFFC107);
                     textColor = Colors.white; 
                  } else if (status.contains("CUTI")) {
                     cellColor = const Color(0xFF9C27B0); // Purple
                     textColor = Colors.white;
                  } else if (status.contains("IZIN")) {
                     cellColor = const Color(0xFF009668); // Teal/Green
                     textColor = Colors.white;
                  } else if (status.contains("TK") || status.contains("TANPA") || status.contains("ALPHA")) {
                      if (dailyData.date.isBefore(DateTime.now())) {
                         cellColor = Colors.red;
                         textColor = Colors.white;
                      }
                  } else if (status.contains("HADIR") || status.contains("TEPAT")) {
                      // Optional: Green for Present? Or keep white/transparent?
                      // User screenshot showed simple numbers for present/normal days.
                      // List view logic matches this (no color).
                  }
                }
              }

              return GestureDetector(
                onTap: () {
                  if (isCurrentMonth && dailyData != null) {
                    final s = dailyData.status.toUpperCase();
                    // Correction Logic
                    if (s.contains('TERLAMBAT') ||
                        s.contains('PULANG CEPAT') ||
                        s.contains('CP')) {
                      if (_isCorrectionAlreadySubmitted(dailyData.rawDate)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Izin TL/CP sudah diajukan"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else if (_isCorrectionAllowed(dailyData.rawDate)) {
                        _showLateReasonModal(context, dailyData.rawDate);
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
                      color: cellColor,
                      borderRadius: BorderRadius.circular(8), // Match list view style roughly
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCurrentMonth ? "$day" : "",
                          style: TextStyle(
                            color: isCurrentMonth ? textColor : Colors.transparent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Today Indicator
                        if (isCurrentMonth &&
                            DateTime.now().year == cellDate.year &&
                            DateTime.now().month == cellDate.month &&
                            DateTime.now().day == cellDate.day)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: textColor == Colors.white ? Colors.white : Colors.blue,
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

// --- REFACTORED MODELS ---

class ScheduleModel {
  final String? startTime;
  final String? endTime;
  final String? shiftName;
  final bool isHoliday;

  ScheduleModel({
    this.startTime,
    this.endTime,
    this.shiftName,
    this.isHoliday = false,
  });

  String get formattedRange {
    if (isHoliday) return "Hari Libur";
    if (startTime == null || endTime == null) return "Jadwal Tidak Tersedia";
    return "$startTime - $endTime";
  }
}

class HistoryDayItem {
  final DateTime date; // Parsed Date Object
  final ScheduleModel? schedule;
  final AttendanceModel? attendance;
  final String status;
  final String rawDate; // Original String Date

  HistoryDayItem({
    required this.date,
    this.schedule,
    this.attendance,
    required this.status,
    required this.rawDate,
  });
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
