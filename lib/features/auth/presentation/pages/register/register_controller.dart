import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../../core/utils/input_validator.dart';

import 'register_presenter.dart';

class RegisterController extends Controller {
  final RegisterPresenter _presenter;

  RegisterController(this._presenter);

  // Text Controllers
  final TextEditingController nipController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController =
      TextEditingController(); // Start with minimal, but Entity supports these
  final TextEditingController phoneController = TextEditingController();

  // State
  bool isLoading = false;
  String? errorMessage;

  @override
  void initListeners() {
    _presenter.onRegisterSuccess = (String message) {
      isLoading = false;
      errorMessage = null;
      refreshUI();
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(SnackBar(content: Text(message)));
      // Determine navigation (e.g. go back to login, or auto login)
      // Usually after register, user is asked to login or auto logged in.
      // User asked: "pilihan untuk login jika dia sudah registrasi".
      // This implies: Go back to login or stay here but show success.
      Navigator.of(getContext()).pop(); // Go back to login
    };

    _presenter.onRegisterError = (e) {
      isLoading = false;
      errorMessage = e.toString();
      refreshUI();
      ScaffoldMessenger.of(getContext()).showSnackBar(
        SnackBar(content: Text('Registrasi Gagal: $errorMessage')),
      );
    };
  }

  void register() {
    final nipError = InputValidator.validateNip(nipController.text);
    final passwordError = InputValidator.validatePassword(
      passwordController.text,
    );
    final nameError = InputValidator.validateName(nameController.text);
    final emailError = InputValidator.validateEmail(emailController.text);
    final phoneError = InputValidator.validatePhone(phoneController.text);

    if (nipError == null &&
        passwordError == null &&
        nameError == null &&
        emailError == null &&
        phoneError == null) {
      isLoading = true;
      errorMessage = null;
      refreshUI();

      _presenter.register(
        nip: nipController.text,
        password: passwordController.text,
        name: nameController.text,
        email: emailController.text.isNotEmpty ? emailController.text : null,
        phone: phoneController.text.isNotEmpty ? phoneController.text : null,
      );
    } else {
      errorMessage =
          nipError ?? passwordError ?? nameError ?? emailError ?? phoneError;
      refreshUI();
    }
  }

  void navigateToLogin() {
    Navigator.of(getContext()).pop();
  }

  @override
  void onDisposed() {
    nipController.dispose();
    nameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _presenter.dispose();
    super.onDisposed();
  }
}
