import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';
import '../../entities/user.dart';

/// GetProfileUseCase
/// Fetches the user profile from the remote data source.
class GetProfileUseCase extends UseCase<User, void> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  GetProfileUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<User>> buildUseCaseStream(void params) async {
    final controller = StreamController<User>();

    try {
      final user = await _authRepository.getProfile();
      controller.add(user);
      _loggerRepository.debug('Get Profile successful for user: ${user.name}');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error(
        'Get Profile failed',
        error: e,
        stackTrace: stackTrace,
      );
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}
