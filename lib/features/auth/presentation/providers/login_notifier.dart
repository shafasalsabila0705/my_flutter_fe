import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'; // Needed for Observer if keeping strict UseCase structure from package, or we implement our own Observer
// Actually, flutter_clean_architecture's UseCase requires an Observer.
// We should implement a simple Observer to bridge UseCase -> Riverpod.

import '../../../../core/utils/input_validator.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login/login_usecase.dart';

// State
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool rememberMe;
  final User? user;

  LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.rememberMe = false,
    this.user,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? rememberMe,
    User? user,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      rememberMe: rememberMe ?? this.rememberMe,
      user: user ?? this.user,
    );
  }
}

// Notifier
class LoginNotifier extends StateNotifier<LoginState> {
  final LoginUseCase _loginUseCase;
  final FlutterSecureStorage _storage;

  LoginNotifier(this._loginUseCase, this._storage) : super(LoginState()) {
    _loadSavedCredentials();
  }

  // To hold initial values for text fields if needed,
  // but better to let UI pull from storage or we provide via a separate method/state.
  String? initialNip;
  String? initialPassword;

  Future<void> _loadSavedCredentials() async {
    try {
      final savedNip = await _storage.read(key: 'REMEMBER_ME_NIP');
      final savedPassword = await _storage.read(key: 'REMEMBER_ME_PASSWORD');

      if (savedNip != null && savedNip.isNotEmpty) {
        initialNip = savedNip;
        // bool hasPassword = savedPassword != null && savedPassword.isNotEmpty; // Unused
        initialPassword = savedPassword;

        state = state.copyWith(rememberMe: true);
      }
    } catch (e) {
      // ignore error
    }
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  Future<void> login(String nip, String password) async {
    // Validation
    final nipError = InputValidator.validateNip(nip);
    final passwordError = InputValidator.validatePassword(password);

    if (nipError != null || passwordError != null) {
      state = state.copyWith(errorMessage: nipError ?? passwordError);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    // Execute UseCase
    // We need an Observer. We can create an anonymous one or a helper class.
    _loginUseCase.execute(
      _LoginObserver(this, nip, password),
      LoginParams(nip, password),
    );
  }

  void _handleSuccess(User user, String nip, String password) async {
    // Handle Remember Me
    if (state.rememberMe) {
      await _storage.write(key: 'REMEMBER_ME_NIP', value: nip);
      await _storage.write(key: 'REMEMBER_ME_PASSWORD', value: password);
    } else {
      await _storage.delete(key: 'REMEMBER_ME_NIP');
      await _storage.delete(key: 'REMEMBER_ME_PASSWORD');
    }

    state = state.copyWith(isLoading: false, isSuccess: true, user: user);
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

// Observer to bridge Clean Architecture UseCase -> Riverpod
class _LoginObserver implements Observer<User> {
  final LoginNotifier _notifier;
  final String nip;
  final String password;

  _LoginObserver(this._notifier, this.nip, this.password);

  @override
  void onNext(User? response) {
    if (response != null) {
      _notifier._handleSuccess(response, nip, password);
    }
  }

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _notifier._handleError(e);
  }
}

// Provider
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(sl<LoginUseCase>(), sl<FlutterSecureStorage>());
});
