import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'data/repositories/logger_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/logger_repository.dart';
import 'features/auth/domain/usecases/login/login_usecase.dart';
import 'features/auth/domain/usecases/register/register_usecase.dart';
import 'features/auth/presentation/pages/login/login_controller.dart';
import 'features/auth/presentation/pages/login/login_presenter.dart';
import 'features/auth/presentation/pages/register/register_controller.dart';
import 'features/auth/presentation/pages/register/register_presenter.dart';
import 'features/dashboard/presentation/pages/dashboard/dashboard_controller.dart';
import 'features/dashboard/presentation/pages/dashboard/dashboard_presenter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';

import 'features/dashboard/data/datasources/attendance_remote_data_source.dart';
import 'features/dashboard/data/repositories/attendance_repository_impl.dart';
import 'features/dashboard/domain/repositories/attendance_repository.dart';

import 'features/dashboard/data/datasources/banner_remote_data_source.dart';
import 'features/dashboard/data/repositories/banner_repository_impl.dart';

import 'features/dashboard/data/datasources/leave_remote_data_source.dart';
import 'features/dashboard/data/repositories/leave_repository_impl.dart';
import 'features/dashboard/domain/repositories/leave_repository.dart';

import 'features/dashboard/data/datasources/koreksi_remote_data_source.dart';
import 'features/dashboard/data/repositories/koreksi_repository_impl.dart';
import 'features/dashboard/domain/repositories/koreksi_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth

  // Controller
  sl.registerFactory(() => LoginController(sl()));
  sl.registerFactory(() => RegisterController(sl()));
  sl.registerFactory(() => DashboardController(sl(), sl(), sl()));

  // Presenter
  sl.registerFactory(() => LoginPresenter(sl()));
  sl.registerFactory(() => RegisterPresenter(sl()));
  sl.registerFactory(() => DashboardPresenter());

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl(), sl()));

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

  // Define Base URLs
  String baseUrl = 'http://172.23.14.88:3000';

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
    print('Error detecting device info: $e');
  }

  print('Using Base URL: $baseUrl');

  sl.registerLazySingleton(
    () => ApiClient(baseUrl: baseUrl, authLocalDataSource: sl()),
  );

  // Secure Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
