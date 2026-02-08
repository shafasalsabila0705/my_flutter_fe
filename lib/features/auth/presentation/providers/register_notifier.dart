import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../core/utils/input_validator.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/register/register_usecase.dart';

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final RegisterUseCase _registerUseCase;

  RegisterNotifier(this._registerUseCase) : super(RegisterState());

  void register({
    required String nip,
    required String password,
    required String name,
    required String confirmPassword,
    String? email,
    String? phone,
  }) {
    // Validation
    final nipError = InputValidator.validateNip(nip);
    final passwordError = InputValidator.validatePassword(password);
    final confirmPasswordError = password != confirmPassword
        ? 'Konfirmasi password tidak cocok'
        : null;
    final nameError = InputValidator.validateName(name);
    final emailError = InputValidator.validateEmail(email ?? '');
    final phoneError = InputValidator.validatePhone(phone ?? '');

    if (nipError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        nameError != null ||
        (email != null && email.isNotEmpty && emailError != null) ||
        (phone != null && phone.isNotEmpty && phoneError != null)) {
      final firstError =
          nipError ??
          passwordError ??
          confirmPasswordError ??
          nameError ??
          (email != null && email.isNotEmpty ? emailError : null) ??
          (phone != null && phone.isNotEmpty ? phoneError : null);

      state = state.copyWith(errorMessage: firstError);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    _registerUseCase.execute(
      _RegisterObserver(this),
      RegisterParams(
        nip: nip,
        password: password,
        name: name,
        email: email,
        phone: phone,
      ),
    );
  }

  void _handleSuccess(String message) {
    state = state.copyWith(isLoading: false, successMessage: message);
  }

  void _handleError(dynamic error) {
    String cleanMessage = error.toString();
    if (cleanMessage.contains('ServerException:')) {
      cleanMessage = cleanMessage.replaceAll('ServerException:', '').trim();
    } else if (cleanMessage.contains('ServerFailure:')) {
      cleanMessage = cleanMessage.replaceAll('ServerFailure:', '').trim();
    } else if (cleanMessage.contains('Exception:')) {
      cleanMessage = cleanMessage.replaceAll('Exception:', '').trim();
    }
    state = state.copyWith(isLoading: false, errorMessage: cleanMessage);
  }
}

class _RegisterObserver extends Observer<String> {
  final RegisterNotifier _notifier;

  _RegisterObserver(this._notifier);

  @override
  void onNext(String? response) {
    if (response != null) {
      _notifier._handleSuccess(response);
    }
  }

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _notifier._handleError(e);
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) {
    return RegisterNotifier(sl<RegisterUseCase>());
  },
);
