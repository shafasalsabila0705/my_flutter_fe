import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../../core/constants/strings.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';

class RegisterUseCase extends UseCase<String, RegisterParams> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  RegisterUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(RegisterParams? params) async {
    final controller = StreamController<String>();

    try {
      if (params == null) {
        controller.addError(Exception(AppStrings.paramsNull));
        controller.close();
        return controller.stream;
      }

      _loggerRepository.debug('Attempting registration for NIP: ${params.nip}');

      // Simple validation
      if (params.password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final message = await _authRepository.register(
        nip: params.nip,
        password: params.password,
        name: params.name,
        email: params.email,
        phone: params.phone,
      );

      controller.add(message);
      _loggerRepository.debug('Registration successful: $message');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error(
        'Registration failed',
        error: e,
        stackTrace: stackTrace,
      );
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}

class RegisterParams {
  final String nip;
  final String password;
  final String name;
  final String? email;
  final String? phone;

  RegisterParams({
    required this.nip,
    required this.password,
    required this.name,
    this.email,
    this.phone,
  });
}
