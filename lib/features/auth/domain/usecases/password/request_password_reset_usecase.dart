import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';

class RequestPasswordResetUseCase extends UseCase<String, String> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  RequestPasswordResetUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(String? nip) async {
    final controller = StreamController<String>();

    try {
      if (nip == null) {
        throw Exception('NIP cannot be null');
      }

      _loggerRepository.debug('Requesting password reset for NIP: $nip');
      final message = await _authRepository.requestPasswordReset(nip);
      controller.add(message);
      _loggerRepository.debug('Password reset requested successfully');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error(
        'Password reset request failed',
        error: e,
        stackTrace: stackTrace,
      );
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}
