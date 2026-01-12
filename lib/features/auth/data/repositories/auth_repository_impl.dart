import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/logger_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LoggerRepository loggerRepository;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.loggerRepository,
  });

  @override
  Future<User> login(String nip, String password) async {
    try {
      final userModel = await remoteDataSource.login(nip, password);
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
}
