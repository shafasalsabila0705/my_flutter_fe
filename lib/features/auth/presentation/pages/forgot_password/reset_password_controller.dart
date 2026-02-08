import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../domain/repositories/auth_repository.dart';
import '../../../../../core/utils/password_validator.dart';

class ResetPasswordController extends fca.Controller {
  final AuthRepository _authRepository;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  String? _nip;
  String? _otp;

  ResetPasswordController(this._authRepository);

  void setParams(String nip, String otp) {
    _nip = nip;
    _otp = otp;
  }

  @override
  void initListeners() {}

  void resetPassword() async {
    // Validation
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showError("Password tidak boleh kosong");
      return;
    }

    if (password != confirm) {
      _showError("Password tidak sama");
      return;
    }

    // Validation using Helper
    final validationError = PasswordValidator.validate(password);
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    isLoading = true;
    refreshUI();
    try {
      final message = await _authRepository.resetPassword(
        _nip!,
        _otp!,
        password,
      );
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(SnackBar(content: Text(message)));

      // Navigate back to Login (remove all routes)
      Navigator.of(getContext()).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading = false;
      refreshUI();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(getContext()).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void onDisposed() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onDisposed();
  }
}
