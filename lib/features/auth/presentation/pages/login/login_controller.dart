import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../../core/utils/input_validator.dart';
import '../../../../../core/providers/user_provider.dart';

import '../../../domain/entities/user.dart';
import 'login_presenter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginController extends Controller {
  final LoginPresenter _presenter;

  LoginController(this._presenter);

  // Text Controllers
  final TextEditingController nipController =
      TextEditingController(); // Changed
  final TextEditingController passwordController = TextEditingController();

  // State
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  @override
  void initListeners() {
    _presenter.onLoginSuccess = (User user) {
      isLoading = false;
      currentUser = user;

      // Update Global State (Riverpod)
      try {
        ProviderScope.containerOf(
          getContext(),
          listen: false,
        ).read(userProvider.notifier).setUser(user);
      } catch (e) {
        // Fallback or log if context or provider scope is missing (unlikely)
        print('Riverpod Error: $e');
      }

      errorMessage = null;
      refreshUI();
      Navigator.of(getContext()).pushReplacementNamed('/dashboard');
    };

    _presenter.onLoginError = (e) {
      isLoading = false;
      // Clean up error message prefix if present
      String cleanMessage = e.toString();
      if (cleanMessage.contains('ServerException:')) {
        cleanMessage = cleanMessage.replaceAll('ServerException:', '').trim();
      } else if (cleanMessage.contains('ServerFailure:')) {
        cleanMessage = cleanMessage.replaceAll('ServerFailure:', '').trim();
      } else if (cleanMessage.contains('Exception:')) {
        cleanMessage = cleanMessage.replaceAll('Exception:', '').trim();
      }

      errorMessage = cleanMessage;
      refreshUI();
      // SnackBar removed as per user request (duplicate alert)
    };
  }

  void login() {
    final nipError = InputValidator.validateNip(nipController.text);
    final passwordError = InputValidator.validatePassword(
      passwordController.text,
    );

    if (nipError == null && passwordError == null) {
      isLoading = true;
      errorMessage = null;
      refreshUI();
      _presenter.login(nipController.text, passwordController.text);
    } else {
      errorMessage = nipError ?? passwordError;
      refreshUI();
    }
  }

  void navigateToRegister() {
    Navigator.of(
      getContext(),
    ).pushNamed('/register'); // Using named route preferred, or direct push
    // For simplicity without route generator:
    // Navigator.push(getContext(), MaterialPageRoute(builder: (_) => RegisterPage()));
    // But RegisterPage needs new import.
    // I will use Navigator.push with import in Controller? No, Controller shouldn't import UI (View).
    // Better: Controller calls a listener method 'onNavigateToRegister' which View implements.
    // OR: Controller uses Navigator with string route.
    // I'll stick to direct push in View for simplicity if Controller is hard.
    // But keeping logic in Controller:
    // I will use Named Route '/register' and define it in main.dart?
    // That's cleaner.
    Navigator.pushNamed(getContext(), '/register');
  }

  @override
  void onDisposed() {
    nipController.dispose();
    passwordController.dispose();
    _presenter.dispose(); // Ensure presenter is disposed
    super.onDisposed();
  }
}
