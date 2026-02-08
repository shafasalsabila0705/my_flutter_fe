import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/logger_repository.dart';

class VerifyOtpUseCase extends UseCase<String, VerifyOtpParams> {
  final AuthRepository _authRepository;
  final LoggerRepository _loggerRepository;

  VerifyOtpUseCase(this._authRepository, this._loggerRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(VerifyOtpParams? params) async {
    final controller = StreamController<String>();

    try {
      if (params == null) {
        throw Exception('Params cannot be null');
      }

      _loggerRepository.debug('Verifying OTP for NIP: ${params.nip}');
      final message = await _authRepository.verifyOtp(params.nip, params.otp);
      controller.add(message);
      _loggerRepository.debug('OTP verified successfully');
      controller.close();
    } catch (e, stackTrace) {
      _loggerRepository.error(
        'OTP verification failed',
        error: e,
        stackTrace: stackTrace,
      );
      controller.addError(e);
      controller.close();
    }

    return controller.stream;
  }
}

class VerifyOtpParams {
  final String nip;
  final String otp;

  VerifyOtpParams(this.nip, this.otp);
}
