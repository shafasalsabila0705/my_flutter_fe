import 'core/network/dio_client.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'core/providers/user_provider.dart';
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
    () => AuthRepositoryImpl(remoteDataSource: sl(), loggerRepository: sl()),
  );

  sl.registerLazySingleton<LoggerRepository>(() => LoggerRepositoryImpl());

  // Core
  sl.registerLazySingleton(() => UserProvider());

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // ! External
  sl.registerLazySingleton(() => DioClient.getDio());
  sl.registerLazySingleton(() => Logger()); // If needed directly
}
