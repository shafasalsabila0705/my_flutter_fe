import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../injection_container.dart';
import '../../domain/usecases/password/verify_otp_usecase.dart';

class OtpVerificationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  OtpVerificationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  OtpVerificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class OtpVerificationNotifier extends StateNotifier<OtpVerificationState> {
  final VerifyOtpUseCase _useCase;

  OtpVerificationNotifier(this._useCase) : super(OtpVerificationState());

  void verifyOtp(String nip, String otp) {
    if (otp.length < 4) {
      state = state.copyWith(errorMessage: 'OTP tidak valid');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    _useCase.execute(_OtpObserver(this), VerifyOtpParams(nip, otp));
  }

  void _handleSuccess(String message) {
    state = state.copyWith(isLoading: false, successMessage: message);
  }

  void _handleError(dynamic error) {
    state = state.copyWith(isLoading: false, errorMessage: error.toString());
  }
}

class _OtpObserver extends Observer<String> {
  final OtpVerificationNotifier _notifier;

  _OtpObserver(this._notifier);

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

final otpVerificationProvider =
    StateNotifierProvider.autoDispose<
      OtpVerificationNotifier,
      OtpVerificationState
    >((ref) {
      return OtpVerificationNotifier(sl<VerifyOtpUseCase>());
    });
