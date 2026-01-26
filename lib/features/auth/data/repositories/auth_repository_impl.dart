import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/logger_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final LoggerRepository loggerRepository;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.loggerRepository,
  });

  @override
  Future<User> login(String nip, String password) async {
    try {
      final userModel = await remoteDataSource.login(nip, password);
      await localDataSource.cacheUser(userModel);
      await localDataSource.cacheToken(
        userModel.token ?? userModel.id,
      ); // Use token if available, else id as fallback
      if (userModel.refreshToken != null) {
        await localDataSource.cacheRefreshToken(userModel.refreshToken!);
      }
      return userModel.toEntity();
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Login failed in repository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String> register({
    required String nip,
    required String password,
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final message = await remoteDataSource.register(
        nip: nip,
        password: password,
        name: name,
        email: email,
        phone: phone,
      );
      return message;
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Registration failed in repository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await localDataSource.clearUser();
      await localDataSource.clearToken();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getLastUser();
      return userModel?.toEntity();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getToken();
    return token != null;
  }

  @override
  Future<User> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();
      await localDataSource.cacheUser(userModel); // Cache fresh data
      return userModel.toEntity();
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Get Profile failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateProfile(data);
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Update Profile failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateAtasan(String atasanId) async {
    try {
      await remoteDataSource.updateAtasan(atasanId);
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Update Atasan failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<User>> getAtasanList() async {
    try {
      final userModels = await remoteDataSource.getAtasanList();
      return userModels.map((e) => e.toEntity()).toList();
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Get Atasan List failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(oldPassword, newPassword);
    } catch (e, stackTrace) {
      loggerRepository.error(
        'Change Password failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
