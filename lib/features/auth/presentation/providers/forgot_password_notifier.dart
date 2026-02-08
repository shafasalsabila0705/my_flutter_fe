import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/password/request_password_reset_usecase.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final RequestPasswordResetUseCase _useCase;

  ForgotPasswordNotifier(this._useCase) : super(ForgotPasswordState());

  void requestOtp(String nip) {
    if (nip.isEmpty) {
      state = state.copyWith(errorMessage: 'NIP tidak boleh kosong');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    _useCase.execute(_ForgotPasswordObserver(this), nip);
  }

  void _handleSuccess(String message) {
    state = state.copyWith(isLoading: false, successMessage: message);
  }

  void _handleError(dynamic error) {
    state = state.copyWith(isLoading: false, errorMessage: error.toString());
  }
}

class _ForgotPasswordObserver extends Observer<String> {
  final ForgotPasswordNotifier _notifier;

  _ForgotPasswordObserver(this._notifier);

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

final forgotPasswordProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordNotifier,
      ForgotPasswordState
    >((ref) {
      return ForgotPasswordNotifier(sl<RequestPasswordResetUseCase>());
    });
