import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../../core/constants/strings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';
import '../../entities/user.dart';

/// LoginUseCase
/// Handles the login business logic.
class LoginUseCase extends UseCase<User, LoginParams> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  LoginUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<User>> buildUseCaseStream(LoginParams? params) async {
    final controller = StreamController<User>();

    try {
      if (params == null) {
        controller.addError(Exception(AppStrings.paramsNull));
        controller.close();
        return controller.stream;
      }

      _loggerRepository.debug('Attempting login for NIP: ${params.nip}');
      final user = await _authRepository.login(params.nip, params.password);
      controller.add(user);
      _loggerRepository.debug('Login successful for user: ${user.name}');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error('Login failed', error: e, stackTrace: stackTrace);
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}

class LoginParams {
  final String nip;
  final String password;

  LoginParams(this.nip, this.password);
}
