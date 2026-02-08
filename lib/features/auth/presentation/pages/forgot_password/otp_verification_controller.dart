import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../domain/repositories/auth_repository.dart';
import 'reset_password_page.dart';

class OtpVerificationController extends fca.Controller {
  final AuthRepository _authRepository;
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  String? _nip;

  OtpVerificationController(this._authRepository);

  void setNip(String nip) {
    _nip = nip;
  }

  @override
  void initListeners() {}

  void verifyOtp() async {
    if (_nip == null) return;
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(const SnackBar(content: Text("OTP harus diisi")));
      return;
    }

    isLoading = true;
    refreshUI();
    try {
      final message = await _authRepository.verifyOtp(
        _nip!,
        otpController.text,
      );
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(SnackBar(content: Text(message)));

      // Navigate to Reset Password Page
      Navigator.pushReplacement(
        getContext(),
        MaterialPageRoute(
          builder: (context) =>
              ResetPasswordPage(nip: _nip!, otp: otpController.text),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      isLoading = false;
      refreshUI();
    }
  }

  @override
  void onDisposed() {
    otpController.dispose();
    super.onDisposed();
  }
}
