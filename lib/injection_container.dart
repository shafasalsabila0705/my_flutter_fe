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

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth

  // Controller
  sl.registerFactory(() => LoginController(sl()));
  sl.registerFactory(() => RegisterController(sl()));
  sl.registerFactory(() => DashboardController(sl()));

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
      localDataSource: sl(), // Now available
      loggerRepository: sl(),
    ),
  );

  sl.registerLazySingleton<LoggerRepository>(() => LoggerRepositoryImpl());

  // Core - Providers are now Riverpod, so no GetIt registration needed for UserProvider
  // sl.registerLazySingleton(() => UserProvider()); // REMOVED

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // ! External

  sl.registerLazySingleton(() => Logger());

  // Define Base URLs
  // Server user provided: http://172.23.14.140:3000/
  // Since this IP (.140) is different from your laptop IP (.143),
  // we treat it as an external server. Both Emulator and Device should reach it directly.
  const String serverBaseUrl = 'http://172.23.14.140:3000';

  String baseUrl = serverBaseUrl;

  // Check if running on Android Emulator
  try {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (!androidInfo.isPhysicalDevice) {
        // If server is on the SAME laptop as emulator, use 10.0.2.2
        // But if server is another machine (.140), use the IP directly.
        // Assuming .140 is external/another machine based on ipconfig difference.
        baseUrl = serverBaseUrl;
      }
    }
  } catch (e) {
    print('Error detecting device info: $e');
  }

  print('Using Base URL: $baseUrl');

  sl.registerLazySingleton(() => ApiClient(baseUrl: baseUrl));

  // Secure Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
