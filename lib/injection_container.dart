import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'core/services/location_service.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'data/repositories/logger_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/logger_repository.dart';
import 'features/auth/domain/usecases/login/login_usecase.dart';
import 'features/auth/domain/usecases/register/register_usecase.dart';
import 'features/auth/domain/usecases/profile/get_profile_usecase.dart';
import 'features/auth/domain/usecases/password/request_password_reset_usecase.dart';
import 'features/auth/domain/usecases/password/verify_otp_usecase.dart';
import 'features/auth/domain/usecases/password/reset_password_usecase.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';

import 'features/dashboard/data/datasources/attendance_remote_data_source.dart';
import 'features/dashboard/data/repositories/attendance_repository_impl.dart';
import 'features/dashboard/domain/repositories/attendance_repository.dart';

import 'features/dashboard/data/datasources/banner_remote_data_source.dart';
import 'features/dashboard/data/repositories/banner_repository_impl.dart';
import 'features/dashboard/domain/repositories/banner_repository.dart';

import 'features/dashboard/data/datasources/leave_remote_data_source.dart';
import 'features/dashboard/data/repositories/leave_repository_impl.dart';
import 'features/dashboard/domain/repositories/leave_repository.dart';

import 'features/dashboard/data/datasources/koreksi_remote_data_source.dart';
import 'features/dashboard/data/repositories/koreksi_repository_impl.dart';
import 'features/dashboard/domain/repositories/koreksi_repository.dart';

import 'features/dashboard/domain/usecases/get_banners_usecase.dart';
import 'features/dashboard/domain/usecases/get_attendance_history_usecase.dart';
import 'features/dashboard/domain/usecases/get_today_attendance_usecase.dart';
import 'features/dashboard/domain/usecases/check_in_usecase.dart';
import 'features/dashboard/domain/usecases/check_out_usecase.dart';
import 'features/auth/domain/usecases/logout/logout_usecase.dart';
import 'features/dashboard/domain/usecases/get_location_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth

  // ! Features - Auth

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RequestPasswordResetUseCase(sl(), sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl(), sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl(), sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  sl.registerLazySingleton(() => GetBannersUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetTodayAttendanceUseCase(sl(), sl()));
  sl.registerLazySingleton(() => CheckInUseCase(sl()));
  sl.registerLazySingleton(() => CheckOutUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      loggerRepository: sl(),
    ),
  );

  sl.registerLazySingleton<LoggerRepository>(() => LoggerRepositoryImpl());

  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<BannerRepository>(
    () => BannerRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<LeaveRepository>(
    () => LeaveRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<KoreksiRepository>(
    () => KoreksiRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<BannerRemoteDataSource>(
    () => BannerRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<LeaveRemoteDataSource>(
    () => LeaveRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<KoreksiRemoteDataSource>(
    () => KoreksiRemoteDataSourceImpl(apiClient: sl()),
  );

  // ! External

  sl.registerLazySingleton(() => Logger());
  sl.registerLazySingleton(() => LocationService());

  // Define Base URLs
  String baseUrl = 'http://192.168.1.14:3000';

  try {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (!androidInfo.isPhysicalDevice) {
        // Emulator localhost
        baseUrl = 'http://10.0.2.2:3000';
      }
    }
  } catch (e) {
    debugPrint('Error detecting device info: $e');
  }

  debugPrint('Using Base URL: $baseUrl');

  sl.registerLazySingleton(
    () => ApiClient(baseUrl: baseUrl, authLocalDataSource: sl()),
  );

  // Secure Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
