import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../injection_container.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/profile/get_profile_usecase.dart';
import '../../../auth/domain/usecases/logout/logout_usecase.dart';

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
    this._ref,
  ) : super(DashboardState());

  void loadDashboardData() {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _getBanners();
    _getHistory();
    _getTodayStatus();
    _refreshProfile();
    _getLocation();
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

  void checkIn(
    double lat,
    double long, {
    File? photo,
    String? reason,
    Function(AttendanceModel)? onSuccess,
    Function(dynamic)? onError,
  }) {
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
    state = state.copyWith(isLoading: true);
    _checkOutUseCase.execute(
      _CheckInOutObserver(this, onSuccess, onError),
      CheckOutParams(lat: lat, long: long),
    );
  }

  void logout() {
    state = state.copyWith(isLoading: true);
    _logoutUseCase.execute(_LogoutObserver(this));
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
    state = state.copyWith(isLoading: false, todayAttendance: result);
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
        ref,
      );
    });
