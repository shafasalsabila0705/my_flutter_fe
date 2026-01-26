import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/custom_dropdown.dart';
import 'leave_menu_page.dart'; // Import custom page

import '../../../../../../injection_container.dart';
import '../../../domain/repositories/attendance_repository.dart';
import '../../../../auth/domain/repositories/auth_repository.dart'; // Import AuthRepository
import '../../../data/models/attendance_model.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';

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

  void _showLateReasonModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder(
          future: sl<AuthRepository>().getCurrentUser(), // Fetch profile
          builder: (context, snapshot) {
            final user = snapshot.data;
            final atasanNama =
                user?.atasanNama ?? user?.atasanId ?? "-"; // Fallback

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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.file_upload_outlined, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Lampirkan Bukti",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize to current month
    // Mapping manually to match _months list (Indonesian)
    int currentMonthIndex = DateTime.now().month - 1;
    _selectedMonth = _months[currentMonthIndex];

    _fetchHistory();
  }

  List<AttendanceModel> _allHistory = []; // Store source of truth

  Future<void> _fetchHistory() async {
    try {
      final repository = sl<AttendanceRepository>();
      final history = await repository.getHistory();

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
        print("Error fetching today status: $e");
      }

      setState(() {
        _allHistory = finalList; // Save unfiltered list
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
    switch (status.toUpperCase()) {
      case 'HADIR':
      case 'TEPAT WAKTU':
        return const Color(0xFF66BB6A);
      case 'TERLAMBAT':
        return const Color(0xFFD32F2F); // Red as requested
      case 'IZIN':
      case 'CUTI':
      case 'SAKIT':
        return const Color(0xFFFFD54F);
      case 'ALPA':
        return const Color(0xFFD32F2F);
      default:
        // Return null for unknown status so calendar doesn't show grey box
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, // Background handled by Stack
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
                // Pushed down to allow overlap
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
                        const SizedBox(
                          height: 60,
                        ), // Space for the floating header overlap
                        _buildTabs(),
                        const SizedBox(height: 20),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], // Blue Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              "REKAP KEHADIRAN TIM",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),

            // Chart
            SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: DonutChartPainter([
                  ChartData(color: const Color(0xFF00C853), value: 85), // Hadir
                  ChartData(color: const Color(0xFFFFAB00), value: 8), // Izin
                  ChartData(color: const Color(0xFFD32F2F), value: 5), // Sakit
                  ChartData(color: const Color(0xFF757575), value: 2), // Alpa
                ]),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "85%",
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        Text(
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

            // Statistics List
            _buildStatRow("Hadir", "85% (170 hari)", const Color(0xFF00C853)),
            const SizedBox(height: 10),
            _buildStatRow("Izin", "8% (16 hari)", const Color(0xFFFFAB00)),
            const SizedBox(height: 10),
            _buildStatRow("Sakit", "5% (10 hari)", const Color(0xFFD32F2F)),
            const SizedBox(height: 10),
            _buildStatRow("Alpa", "2% (4 hari)", const Color(0xFF757575)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Glassy effect inside card
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
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
              opacity: 0.15,
              blur: 15,
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
        const SizedBox(width: 12),
        GlassCard(
          borderRadius: 20,
          opacity: 0.3,
          child: IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaveMenuPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    // Watch User State
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final role = user?.role ?? '';
    final bool isAtasan =
        role.isNotEmpty &&
        (role.toLowerCase().contains('admin') ||
            role.toLowerCase().contains('atasan'));

    if (!isAtasan) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF006064),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text(
            "Riwayat Saya",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF006064), // Dark Teal like screenshot
        borderRadius: BorderRadius.circular(10),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF006064), width: 2)
              : null,
        ),
        margin: const EdgeInsets.all(2),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF006064) : Colors.white,
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
                      color: const Color(0xFF1565C0).withOpacity(0.7),
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
              setState(() => _selectedMonth = val!);
            },
            hint: "Pilih Bulan",
            prefixIcon: null, // Icons inside items now
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilter, // Trigger filter on click
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0), // Dark Blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Pilih",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
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

  Map<String, dynamic> _calculateSummaryData() {
    int presentCount = 0;
    int totalLateMinutes = 0;
    int totalWorkMinutes = 0;
    int workDaysCount = 0;

    // Determine context year/month for calculation
    int currentYear = DateTime.now().year;
    int currentMonthIndex = _months.indexOf(_selectedMonth) + 1;

    // Calculate total possible working days for this specific month
    int totalWorkingDays = _getWorkingDaysInMonth(
      currentYear,
      currentMonthIndex,
    );

    for (var item in _historyList) {
      // 1. Calculate Presence
      final status = item.status.toUpperCase();
      if ([
        'HADIR',
        'TEPAT WAKTU',
        'TERLAMBAT',
        'PULANG CEPAT',
      ].contains(status)) {
        presentCount++;
      }

      // Time Helpers
      DateTime? parseTime(String? timeStr) {
        if (timeStr == null || timeStr == '-' || timeStr.isEmpty) return null;
        try {
          // Normalizes HH:mm or HH:mm:ss
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

      // 2. Calculate Late (TL + CP)
      if (checkIn != null && scheduledIn != null) {
        if (checkIn.isAfter(scheduledIn)) {
          totalLateMinutes += checkIn.difference(scheduledIn).inMinutes;
        }
      }
      if (checkOut != null && scheduledOut != null) {
        if (checkOut.isBefore(scheduledOut)) {
          totalLateMinutes += scheduledOut.difference(checkOut).inMinutes;
        }
      }

      // 3. Calculate Work Duration
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn).inMinutes;
        if (duration > 0) {
          totalWorkMinutes += duration;
          workDaysCount++;
        }
      }
    }

    // Format Helpers
    String formatDuration(int minutes) {
      if (minutes == 0) return "0 menit";
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h > 0 && m > 0) return "$h jam $m menit";
      if (h > 0) return "$h jam";
      return "$m menit";
    }

    // Averages
    int avgWorkMinutes = workDaysCount > 0
        ? (totalWorkMinutes / workDaysCount).round()
        : 0;

    return {
      "hari_kerja": "$presentCount/$totalWorkingDays hari",
      "terlambat": formatDuration(totalLateMinutes),
      "jam_kerja": formatDuration(avgWorkMinutes),
    };
  }

  Widget _buildSummaryCards() {
    final summary = _calculateSummaryData();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildCard(
              "Hari Kerja",
              summary['hari_kerja'],
              const Color(0xFF66BB6A),
              Icons.calendar_today,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCard(
              "Terlambat",
              summary['terlambat'],
              const Color(0xFFD32F2F),
              Icons.assignment_late_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCard(
              "Jam Kerja (Rata2)", // Clarified label
              summary['jam_kerja'],
              const Color(0xFF0288D1),
              Icons.work_outline,
            ),
          ),
        ],
      ),
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
            color: color.withOpacity(0.4),
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
              if (item.status == 'TERLAMBAT') {
                _showLateReasonModal(context);
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
                    color: color.withOpacity(0.2), // Light bg
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
                      Text(
                        item.status,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                });
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
                });
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
                  if (isCurrentMonth &&
                      dailyData != null &&
                      dailyData.status == 'TERLAMBAT') {
                    _showLateReasonModal(context);
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
      ..color = Colors.white.withOpacity(0.2)
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
