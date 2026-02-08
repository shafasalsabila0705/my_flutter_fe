import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/password/reset_password_usecase.dart';

class ResetPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  ResetPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ResetPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final ResetPasswordUseCase _useCase;

  ResetPasswordNotifier(this._useCase) : super(ResetPasswordState());

  void resetPassword(
    String nip,
    String otp,
    String newPassword,
    String confirmPassword,
  ) {
    if (newPassword != confirmPassword) {
      state = state.copyWith(errorMessage: 'Konfirmasi password tidak cocok');
      return;
    }
    if (newPassword.length < 6) {
      state = state.copyWith(errorMessage: 'Password minimal 6 karakter');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    _useCase.execute(
      _ResetPasswordObserver(this),
      ResetPasswordParams(nip, otp, newPassword),
    );
  }

  void _handleSuccess(String message) {
    state = state.copyWith(isLoading: false, successMessage: message);
  }

  void _handleError(dynamic error) {
    state = state.copyWith(isLoading: false, errorMessage: error.toString());
  }
}

class _ResetPasswordObserver extends Observer<String> {
  final ResetPasswordNotifier _notifier;

  _ResetPasswordObserver(this._notifier);

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

final resetPasswordProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordNotifier,
      ResetPasswordState
    >((ref) {
      return ResetPasswordNotifier(sl<ResetPasswordUseCase>());
    });
