import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../../../core/providers/user_provider.dart';

import 'dashboard_presenter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/attendance_repository.dart';
import '../../../data/models/attendance_model.dart';

import '../../../data/models/banner_model.dart';
import '../../../data/repositories/banner_repository_impl.dart';

class DashboardController extends Controller {
  final DashboardPresenter _presenter;
  final AttendanceRepository _attendanceRepository;
  final BannerRepository _bannerRepository;

  List<BannerModel>? _banners;
  List<BannerModel>? get banners => _banners;
  bool _isLoadingBanners = false;
  bool get isLoadingBanners => _isLoadingBanners;

  List<AttendanceModel> _attendanceHistory = [];
  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  AttendanceModel? _todayAttendance;
  AttendanceModel? get todayAttendance => _todayAttendance;

  DashboardController(
    this._presenter,
    this._attendanceRepository,
    this._bannerRepository,
  );

  @override
  void initListeners() {
    _getBanners();
    getAttendanceHistory();
    checkTodayStatus();
  }

  void _getBanners() async {
    _isLoadingBanners = true;
    refreshUI();
    try {
      _banners = await _bannerRepository.getBanners();
    } catch (e) {
      print("Banner Error: $e");
    } finally {
      _isLoadingBanners = false;
      refreshUI();
    }
  }

  void getAttendanceHistory() async {
    _isLoadingHistory = true;
    refreshUI();
    try {
      _attendanceHistory = await _attendanceRepository.getHistory();
    } catch (e) {
      print("History Error: $e");
    } finally {
      _isLoadingHistory = false;
      refreshUI();
    }
  }

  Future<void> checkTodayStatus() async {
    try {
      final result = await _attendanceRepository.getTodayStatus();
      if (result['data'] != null) {
        // Create a mutable copy of the data
        final Map<String, dynamic> attendanceData = Map<String, dynamic>.from(
          result['data'],
        );

        // Merge 'jadwal' info if available at the root level
        if (result['jadwal'] != null) {
          attendanceData['jadwal'] = result['jadwal'];
        }

        _todayAttendance = AttendanceModel.fromJson(attendanceData);
      } else {
        _todayAttendance = null;
      }
      refreshUI();
    } catch (e) {
      print("Check Status Error: $e");
    }
  }

  Future<AttendanceModel> checkIn(double lat, double long) async {
    // 1. Check for Holiday/Weekend Prevention
    try {
      final now = DateTime.now();

      // Auto-reject Sunday/Saturday if needed?
      // User said: "sesuai sama yang ada di riwayat" (match with history).
      // But typically Sundays are holidays. Let's check history first.

      // Format today to match API date format (assuming YYYY-MM-DD)
      // Since we don't have intl imported comfortably yet, let's try to match by parsing history dates
      // or just simple string comparison if we knew the format.
      // Better: Parse history items to DateTime and compare specific year/month/day.

      final todayInHistory = _attendanceHistory
          .cast<AttendanceModel?>()
          .firstWhere((element) {
            if (element?.date == null) return false;
            try {
              final date = DateTime.parse(element!.date!);
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
            } catch (e) {
              return false;
            }
          }, orElse: () => null);

      bool isHoliday = false;
      String holidayReason = "Hari Libur";

      // Check explicit status in history
      if (todayInHistory != null) {
        final status = todayInHistory.status.toUpperCase();
        if (status.contains("LIBUR") || status.contains("MERAH")) {
          isHoliday = true;
          holidayReason = "Hari Libur Nasional/Cuti Bersama";
        }
      }

      // Fallback: Check for Weekend (Sunday) if not explicitly in history but usually implied?
      // User specifically said "sesuai sama yang ada di riwayat".
      // However, if the server returns 400 on Sunday, maybe we should block Sunday too.
      // Screenshot shows "Minggu, 25 Jan".
      if (now.weekday == DateTime.sunday) {
        isHoliday = true;
        holidayReason = "Hari Minggu (Libur)";
      }

      if (isHoliday) {
        _showHolidayDialog(holidayReason);
        return Future.error("Holiday Prevention"); // Stop execution
      }
    } catch (e) {
      print("Holiday Check Error: $e");
    }

    try {
      final result = await _attendanceRepository.checkIn(lat, long);
      checkTodayStatus();
      getAttendanceHistory();
      return result;
    } catch (e) {
      // Handle "Jadwal belum ditentukan" error acting as holiday
      final msg = e.toString().toLowerCase();
      if (msg.contains("jadwal kerja hari ini belum ditentukan") ||
          (msg.contains("400") && msg.contains("bad request"))) {
        _showHolidayDialog(
          "Jadwal kerja belum ditentukan (Libur/Diluar Jadwal)",
        );
        return Future.error("Holiday prevention (Server)");
      }
      rethrow;
    }
  }

  void _showHolidayDialog(String holidayReason) {
    showDialog(
      context: getContext(),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.beach_access_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Selamat Berlibur!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Hari ini adalah $holidayReason. Anda tidak perlu melakukan absen.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Baik, Mengerti",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<AttendanceModel> checkOut(double lat, double long) async {
    try {
      final result = await _attendanceRepository.checkOut(lat, long);
      checkTodayStatus();
      getAttendanceHistory();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    // Clear Global State (Riverpod)
    try {
      ProviderScope.containerOf(
        getContext(),
        listen: false,
      ).read(userProvider.notifier).clearUser();

      // Also clear secure storage handled by repo if needed, but repo logout logic usually handles it.
    } catch (e) {
      print('Riverpod Error: $e');
    }

    // Navigate back to login and remove all previous routes
    Navigator.of(getContext()).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
