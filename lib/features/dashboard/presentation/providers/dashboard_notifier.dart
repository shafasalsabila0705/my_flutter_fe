import 'dart:io';
import 'dart:async'; // Added for Completer
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../injection_container.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/profile/get_profile_usecase.dart';
import '../../../auth/domain/usecases/logout/logout_usecase.dart';
import '../../../auth/domain/usecases/profile/get_bawahan_list_usecase.dart'; // Added

import '../../data/models/banner_model.dart';
import '../../data/models/attendance_model.dart';

import '../../domain/usecases/get_banners_usecase.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import '../../domain/usecases/get_today_attendance_usecase.dart';
import '../../domain/usecases/check_in_usecase.dart';
import '../../domain/usecases/check_out_usecase.dart';
import '../../domain/usecases/get_location_usecase.dart';

// State
class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final List<BannerModel> banners;
  final List<AttendanceModel> history;
  final List<User> bawahanList; // Added bawahanList
  final AttendanceModel? todayAttendance;

  // Location State
  final String currentLocationName;
  final bool isOutsideRadius;
  final double? currentLat;
  final double? currentLong;

  DashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.banners = const [],
    this.history = const [],
    this.bawahanList = const [], // Init empty
    this.todayAttendance,
    this.currentLocationName = "Memuat lokasi...",
    this.isOutsideRadius = true,
    this.currentLat,
    this.currentLong,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BannerModel>? banners,
    List<AttendanceModel>? history,
    List<User>? bawahanList, // Added
    AttendanceModel? todayAttendance,
    String? currentLocationName,
    bool? isOutsideRadius,
    double? currentLat,
    double? currentLong,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      banners: banners ?? this.banners,
      history: history ?? this.history,
      bawahanList: bawahanList ?? this.bawahanList, // Added
      todayAttendance: todayAttendance ?? this.todayAttendance,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      isOutsideRadius: isOutsideRadius ?? this.isOutsideRadius,
      currentLat: currentLat ?? this.currentLat,
      currentLong: currentLong ?? this.currentLong,
    );
  }
}

// Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final GetBannersUseCase _getBannersUseCase;
  final GetAttendanceHistoryUseCase _getHistoryUseCase;
  final GetTodayAttendanceUseCase _getTodayUseCase;
  final CheckInUseCase _checkInUseCase;
  final CheckOutUseCase _checkOutUseCase;
  final GetProfileUseCase _getProfileUseCase;
  final GetLocationUseCase _getLocationUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetBawahanListUseCase _getBawahanListUseCase; // Added
  final Ref _ref;

  DashboardNotifier(
    this._getBannersUseCase,
    this._getHistoryUseCase,
    this._getTodayUseCase,
    this._checkInUseCase,
    this._checkOutUseCase,
    this._getProfileUseCase,
    this._getLocationUseCase,
    this._logoutUseCase,
    this._getBawahanListUseCase, // Added
    this._ref,
  ) : super(DashboardState());

  void loadDashboardData() {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _getBanners();
    _getHistory();
    _getTodayStatus();
    _refreshProfile();
    _getLocation();
    loadBawahanList();
  }

  void loadBawahanList() {
    // Optional: state = state.copyWith(isLoading: true);
    // If we want to show loading spinner for it.
    _getBawahanListUseCase.execute(_BawahanListObserver(this));
  }

  void _getBanners() {
    _getBannersUseCase.execute(_BannersObserver(this));
  }

  void _getHistory() {
    _getHistoryUseCase.execute(_HistoryObserver(this));
  }

  void _getTodayStatus() {
    _getTodayUseCase.execute(_TodayObserver(this));
  }

  void _refreshProfile() {
    _getProfileUseCase.execute(_ProfileObserver(this));
  }

  void _getLocation() {
    _getLocationUseCase.execute(_LocationObserver(this));
  }

  /// Strict Schedule Validation (Hit API directly)
  Future<bool> validateSchedule() async {
    try {
      // We use the existing usecase but await the result via a Completer or similar if needed.
      // Since clean architecture UseCases use Observers (Stream/Void), we might need a direct Future call
      // OR we can trust the `state.todayAttendance` IF we force a refresh first?
      // BUT user wants "Hit API".
      // The `GetTodayAttendanceUseCase` returns `Stream<AttendanceModel?>`.
      // We can wrap it or just use the repository directly if we truly need strict "await".
      // However, to stick to Clean Arch, let's use the Use Case and wait for the state to update?
      // No, that's async/reactive.
      // Better approach for "Blocking Check":
      // We can reuse `_getTodayStatus()` but we need to know WHEN it finishes.
      // Simpler: Just check `state.todayAttendance`? NO, user said "Hit API".

      // OPTION: Create a specialized UseCase that returns a Future<bool> or
      // modify GetTodayAttendanceUseCase to allow awaiting?
      // Or simply:

      // final result = await _getTodayUseCase.repository.getTodayStatus();
      // Wait, we shouldn't access repo directly from Notifier usually, but we need a synchronous-like waiting.
      // Let's look at `GetTodayAttendanceUseCase`.

      // Actually, looking at `GetTodayAttendanceUseCase`, it likely calls `repository.getTodayStatus()`.
      // Let's see if we can expose a "checkSchedule" method.

      // A quick way for now without breaking architecture too much:
      // We will perform the check inside Notifier by invoking the repository/usecase
      // but we need to return the result to the UI.

      // Let's implement a fresh fetch here.
      // Since we don't have direct access to repo here (it's injected into UseCase),
      // we might need to add a method to `GetTodayAttendanceUseCase` that returns Future.
      // OR, we can just assume `loadDashboardData` is called often.

      // User said: "Sistem wajib melakukan hit API ke backend Go".
      // So let's add `Future<bool> hasSchedule()` to `DashboardNotifier`
      // which calls a new method or repurposes existing one.

      // To keep it clean, let's look at `_getTodayUseCase`.
      // If it returns a Stream, we can't easily "await" single result unless we listen.

      // Let's cheat slightly for "Blocking UI Action" by using `state` if it was just refreshed?
      // No, user wants fresh hit.

      // Correct way: Add `Future<AttendanceModel> fetchToday()` to parameters/interfaces?
      // Or just add `validateTodaySchedule` to `DashboardNotifier` that manually calls the repo?
      // But repo is not in Notifier. UseCase is.

      // Let's assume we can add a method to the UseCase or just create a new one.
      // Or... we can use `_getTodayUseCase.execute` and wait for the observer?

      // Let's try to add a helper in Notifier that effectively does the work.
      // But we can't access repo.

      // OK, I'll add `Future<bool> checkScheduleExistence()` to the UseCase?
      // No, UseCase standard is `buildUseCaseStream`.

      // Let's look at `AttendanceRemoteDataSource`. It has `getTodayStatus`.
      // The `AttendanceRepository` calls this.
      // The `GetTodayAttendanceUseCase` calls repository.

      // I will add a `Future<bool> validateSchedule()` to `DashboardNotifier`.
      // Since I can't await the UseCase easily without a Completer...
      // I will implement a "manual" await using a one-off observer/completer.

      final completer = Completer<bool>();

      _getTodayUseCase.execute(_ValidatorObserver(this, completer));

      final result = await completer.future;
      debugPrint("--- SCHEDULE VALIDATION ---");
      debugPrint("VALIDATION RESULT: $result");
      debugPrint("CURRENT STATE ATTENDANCE: ${state.todayAttendance}");
      debugPrint(
        "SCHEDULE IN STATE: ${state.todayAttendance?.scheduledCheckInTime}",
      );
      debugPrint("----------------------------");
      return result;
    } catch (e) {
      debugPrint("Validation Error: $e");
      return false;
    }
  }

  void checkIn(
    double lat,
    double long, {
    File? photo,
    String? reason,
    Function(AttendanceModel)? onSuccess,
    Function(dynamic)? onError,
  }) {
    // 1. Validate Schedule
    final schedule = state.todayAttendance?.scheduledCheckInTime;
    if (schedule == null || schedule == '-') {
      onFailure("Anda tidak memiliki jadwal hari ini.");
      if (onError != null) onError("Anda tidak memiliki jadwal hari ini.");
      return;
    }

    // Parse Schedule Time
    try {
      final now = DateTime.now();
      final scheduleTime = _parseTime(schedule, now);

      // Calculate limit (1 hour before schedule)
      final earlyLimit = scheduleTime.subtract(const Duration(hours: 1));

      if (now.isBefore(earlyLimit)) {
        final diff = earlyLimit.difference(now);
        final waitingMinutes = diff.inMinutes;
        final formattedLimit =
            "${earlyLimit.hour.toString().padLeft(2, '0')}:${earlyLimit.minute.toString().padLeft(2, '0')}";

        final msg =
            "Belum saatnya absen. Bisa absen mulai pukul $formattedLimit ($waitingMinutes menit lagi).";

        onFailure(msg);
        if (onError != null) onError(msg);
        return;
      }
    } catch (e) {
      // Only log parsing error, don't block if format is unexpected, or block?
      // Safer to allowed if parsing fails or block?
      // Let's block implies data integrity issue.
      debugPrint("Time Parsing Error: $e");
    }

    state = state.copyWith(isLoading: true);
    _checkInUseCase.execute(
      _CheckInOutObserver(this, onSuccess, onError),
      CheckInParams(lat: lat, long: long, photo: photo, reason: reason),
    );
  }

  void checkOut(
    double lat,
    double long, {
    Function(AttendanceModel)? onSuccess,
    Function(dynamic)? onError,
  }) {
    // 1. Validate Schedule
    final schedule = state.todayAttendance?.scheduledCheckOutTime;

    // If no schedule (e.g. holiday or free), usually we allow checkout if checked in?
    // But user asked: "kalau pulang, kasi juga batasannya".
    // Assume if no schedule, we might block or allow.
    // "kalau dia ga ada jadwal... anda tidak memiliki jadwal hari ini" -> logic for Check In.
    // Logic for Check Out implies same check?
    if (schedule == null || schedule == '-') {
      // If already checked in, maybe we shouldn't block checkout even if no schedule?
      // But user requirement implies strict schedule.
      // Let's check logic: if checked in, they must have had a schedule or bypassed it.
      // If we strictly follow "No schedule = No action".
      onFailure("Tidak ada jadwal pulang hari ini.");
      if (onError != null) onError("Tidak ada jadwal pulang hari ini.");
      return;
    }

    try {
      final now = DateTime.now();
      final scheduleTime = _parseTime(schedule, now);

      // Calculate limit (2 hours after schedule)
      final lateLimit = scheduleTime.add(const Duration(hours: 2));

      if (now.isAfter(lateLimit)) {
        final msg =
            "Batas waktu absen pulang telah habis (Maksimal 2 jam setelah jadwal).";
        onFailure(msg);
        if (onError != null) onError(msg);
        return;
      }
    } catch (e) {
      debugPrint("Time Parsing Error: $e");
    }

    state = state.copyWith(isLoading: true);
    _checkOutUseCase.execute(
      _CheckInOutObserver(this, onSuccess, onError),
      CheckOutParams(lat: lat, long: long),
    );
  }

  DateTime _parseTime(String timeStr, DateTime referenceDate) {
    // Expected format: "HH:mm:ss" or "HH:mm"
    final parts = timeStr.split(':');
    if (parts.length < 2) {
      throw FormatException("Invalid time format: $timeStr");
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final second = parts.length > 2 ? int.parse(parts[2]) : 0;

    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour,
      minute,
      second,
    );
  }

  void logout() {
    state = state.copyWith(isLoading: true);
    _logoutUseCase.execute(_LogoutObserver(this));
  }

  void onBawahanListReceived(List<User> list) {
    state = state.copyWith(bawahanList: list);
  }

  // Callbacks
  void onBannersReceived(List<BannerModel> banners) {
    state = state.copyWith(banners: banners);
    _checkLoading();
  }

  void onHistoryReceived(List<AttendanceModel> history) {
    state = state.copyWith(history: history);
    _checkLoading();
  }

  void onTodayReceived(AttendanceModel? today) {
    state = state.copyWith(todayAttendance: today);
    _checkLoading();
  }

  void onProfileReceived(User user) {
    _ref.read(userProvider.notifier).setUser(user);
  }

  void onLocationReceived(LocationResult result) {
    state = state.copyWith(
      currentLocationName: result.address,
      isOutsideRadius: !result.isWithinRadius,
      currentLat: result.position.latitude,
      currentLong: result.position.longitude,
    );
  }

  void onCheckInOutSuccess(AttendanceModel result) {
    debugPrint("--- CHECK-IN/OUT SUCCESS RAW RESULT ---");
    debugPrint("RESULT JSON: ${result.toJson()}");
    debugPrint("----------------------------------------");

    // PRESERVE DATA: If the new result (usually a checkout) is missing check-in data
    // that we already have in the current state, merge them.
    AttendanceModel finalizedResult = result;

    if (state.todayAttendance != null) {
      final current = state.todayAttendance!;
      final bool newHasCheckIn =
          result.checkInTime != '-' && result.checkInTime.isNotEmpty;
      final bool oldHasCheckIn =
          current.checkInTime != '-' && current.checkInTime.isNotEmpty;

      if (!newHasCheckIn && oldHasCheckIn) {
        finalizedResult = result.copyWith(
          checkInTime: current.checkInTime,
          checkInCoordinates: current.checkInCoordinates,
          status: current.status, // Preserve check-in status
          scheduledCheckInTime:
              result.scheduledCheckInTime ?? current.scheduledCheckInTime,
          scheduledCheckOutTime:
              result.scheduledCheckOutTime ?? current.scheduledCheckOutTime,
          // Distance might also be useful to keep if checkout one is null
          distance: result.distance ?? current.distance,
          statusKeluar: result.statusKeluar ?? current.statusKeluar,
          statusLokasiMasuk:
              result.statusLokasiMasuk ?? current.statusLokasiMasuk,
          statusLokasiPulang:
              result.statusLokasiPulang ?? current.statusLokasiPulang,
        );
      }
    }

    state = state.copyWith(isLoading: false, todayAttendance: finalizedResult);
    _getHistory();
  }

  void onLogoutSuccess() {
    state = state.copyWith(isLoading: false);
    _ref.read(userProvider.notifier).clearUser();
  }

  void onFailure(dynamic error) {
    state = state.copyWith(isLoading: false, errorMessage: error.toString());
  }

  void _checkLoading() {
    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Observers
class _BannersObserver extends Observer<List<BannerModel>> {
  final DashboardNotifier _notifier;
  _BannersObserver(this._notifier);
  @override
  void onNext(List<BannerModel>? response) {
    if (response != null) _notifier.onBannersReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    _notifier.onFailure(e);
  }
}

class _HistoryObserver extends Observer<List<AttendanceModel>> {
  final DashboardNotifier _notifier;
  _HistoryObserver(this._notifier);
  @override
  void onNext(List<AttendanceModel>? response) {
    if (response != null) _notifier.onHistoryReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    _notifier.onFailure(e);
  }
}

class _TodayObserver extends Observer<AttendanceModel?> {
  final DashboardNotifier _notifier;
  _TodayObserver(this._notifier);
  @override
  void onNext(AttendanceModel? response) {
    _notifier.onTodayReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    _notifier.onFailure(e);
  }
}

class _CheckInOutObserver extends Observer<AttendanceModel> {
  final DashboardNotifier _notifier;
  final Function(AttendanceModel)? onSuccess;
  final Function(dynamic)? onErrorCallback;

  _CheckInOutObserver(this._notifier, [this.onSuccess, this.onErrorCallback]);

  @override
  void onNext(AttendanceModel? response) {
    if (response != null) {
      _notifier.onCheckInOutSuccess(response);
      if (onSuccess != null) onSuccess!(response);
    }
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    _notifier.onFailure(e);
    if (onErrorCallback != null) onErrorCallback!(e);
  }
}

class _ProfileObserver extends Observer<User> {
  final DashboardNotifier _notifier;
  _ProfileObserver(this._notifier);
  @override
  void onNext(User? response) {
    if (response != null) _notifier.onProfileReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    // Silent error for profile refresh
  }
}

class _LocationObserver extends Observer<LocationResult> {
  final DashboardNotifier _notifier;
  _LocationObserver(this._notifier);
  @override
  void onNext(LocationResult? response) {
    if (response != null) _notifier.onLocationReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    _notifier.onFailure("Gagal memuat lokasi: $e");
  }
}

class _LogoutObserver extends Observer<void> {
  final DashboardNotifier _notifier;
  _LogoutObserver(this._notifier);
  @override
  void onNext(void response) {}
  @override
  void onComplete() {
    _notifier.onLogoutSuccess();
  }

  @override
  void onError(e) {
    _notifier.onFailure(e);
  }
}

class _BawahanListObserver extends Observer<List<User>> {
  final DashboardNotifier _notifier;
  _BawahanListObserver(this._notifier);
  @override
  void onNext(List<User>? response) {
    if (response != null) _notifier.onBawahanListReceived(response);
  }

  @override
  void onComplete() {}
  @override
  void onError(e) {
    // Silent error or log?
    debugPrint("Failed to load bawahan list: $e");
  }
}

class _ValidatorObserver extends Observer<AttendanceModel?> {
  final DashboardNotifier _notifier;
  final Completer<bool> _completer;

  _ValidatorObserver(this._notifier, this._completer);

  @override
  void onNext(AttendanceModel? response) {
    if (response != null) {
      // Logic to check if schedule exists
      final hasSchedule =
          (response.scheduledCheckInTime != null &&
          response.scheduledCheckInTime != '-' &&
          response.scheduledCheckInTime!.isNotEmpty);

      debugPrint("--- VALIDATOR DEBUG ---");
      debugPrint("JSON: ${response.toJson()}");
      debugPrint("Status: ${response.status}");
      debugPrint("Schedule Masuk: ${response.scheduledCheckInTime}");
      debugPrint("Schedule Pulang: ${response.scheduledCheckOutTime}");
      debugPrint("Date: ${response.date}");
      debugPrint("HasSchedule Logic: $hasSchedule");
      debugPrint("-----------------------");

      if (!_completer.isCompleted) {
        _completer.complete(hasSchedule);
      }

      // Also update state while we're at it
      _notifier.onTodayReceived(response);
    } else {
      if (!_completer.isCompleted) _completer.complete(false);
    }
  }

  @override
  void onComplete() {}

  @override
  void onError(e) {
    debugPrint("VALIDATOR ERROR: $e");
    if (!_completer.isCompleted) {
      _completer.complete(false); // Assume no schedule on error
    }
  }
}

final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(
        sl<GetBannersUseCase>(),
        sl<GetAttendanceHistoryUseCase>(),
        sl<GetTodayAttendanceUseCase>(),
        sl<CheckInUseCase>(),
        sl<CheckOutUseCase>(),
        sl<GetProfileUseCase>(),
        sl<GetLocationUseCase>(),
        sl<LogoutUseCase>(),
        sl<GetBawahanListUseCase>(),
        ref,
      );
    });
