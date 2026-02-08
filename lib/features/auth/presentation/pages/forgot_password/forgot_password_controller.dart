import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../domain/repositories/auth_repository.dart';
import 'otp_verification_page.dart';

class ForgotPasswordController extends fca.Controller {
  final AuthRepository _authRepository;
  final TextEditingController nipController = TextEditingController();
  bool isLoading = false;

  ForgotPasswordController(this._authRepository);

  @override
  void initListeners() {
    // No specific listeners needed yet
  }

  void requestOtp() async {
    if (nipController.text.isEmpty) {
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(const SnackBar(content: Text("NIP tidak boleh kosong")));
      return;
    }

    isLoading = true;
    refreshUI();
    try {
      final message = await _authRepository.requestPasswordReset(
        nipController.text,
      );
      ScaffoldMessenger.of(
        getContext(),
      ).showSnackBar(SnackBar(content: Text(message)));
      // Navigate to OTP Page
      Navigator.push(
        getContext(),
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(nip: nipController.text),
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
    nipController.dispose();
    super.onDisposed();
  }
}
