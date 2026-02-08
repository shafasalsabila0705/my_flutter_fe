import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../widgets/auth_header.dart';
import '../../providers/forgot_password_notifier.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController _nipController = TextEditingController();

  @override
  void dispose() {
    _nipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final notifier = ref.read(forgotPasswordProvider.notifier);

    ref.listen(forgotPasswordProvider, (previous, next) {
      if (next.successMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(nip: _nipController.text),
          ),
        );
      }

      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AuthHeader(
                title: "Lupa Password",
                subtitle: "Reset Kata Sandi Anda",
                version: "",
              ),

              const SizedBox(height: 40),

              const Text(
                "Masukkan NIP Anda untuk menerima kode OTP verifikasi.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 32),

              CustomTextField(
                controller: _nipController,
                label: "NIP",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: "Kirim OTP",
                onPressed: () {
                  notifier.requestOtp(_nipController.text);
                },
                isLoading: state.isLoading,
                icon: Icons.send_rounded,
              ),

              const SizedBox(height: 24),

              // Back to Login Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Kembali ke Login",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
