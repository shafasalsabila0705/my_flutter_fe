import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';

class ResetPasswordUseCase extends UseCase<String, ResetPasswordParams> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  ResetPasswordUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(ResetPasswordParams? params) async {
    final controller = StreamController<String>();

    try {
      if (params == null) {
        throw Exception('Params cannot be null');
      }

      _loggerRepository.debug('Resetting password for NIP: ${params.nip}');
      final message = await _authRepository.resetPassword(
        params.nip,
        params.otp,
        params.newPassword,
      );
      controller.add(message);
      _loggerRepository.debug('Password reset successfully');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error(
        'Password reset failed',
        error: e,
        stackTrace: stackTrace,
      );
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}

class ResetPasswordParams {
  final String nip;
  final String otp;
  final String newPassword;

  ResetPasswordParams(this.nip, this.otp, this.newPassword);
}
