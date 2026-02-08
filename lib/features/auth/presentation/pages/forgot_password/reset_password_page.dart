import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../widgets/auth_header.dart';
import '../../providers/reset_password_notifier.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String nip;
  final String otp;
  const ResetPasswordPage({super.key, required this.nip, required this.otp});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordProvider);
    final notifier = ref.read(resetPasswordProvider.notifier);

    ref.listen(resetPasswordProvider, (previous, next) {
      if (next.successMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to Login (remove all routes until login)
        // Login is typically '/' or we can pop until first.
        Navigator.of(context).popUntil((route) => route.isFirst);
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
                title: "Reset Password",
                subtitle: "Buat Password Baru",
                version: "",
              ),
              const SizedBox(height: 40),

              const Text(
                "Silakan buat password baru untuk akun Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // New Password
              CustomTextField(
                controller: _passwordController,
                label: "Password Baru",
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              CustomTextField(
                controller: _confirmPasswordController,
                label: "Konfirmasi Password",
                isPassword: true,
              ),

              const SizedBox(height: 32),
              CustomButton(
                text: "Simpan Password",
                onPressed: () {
                  notifier.resetPassword(
                    widget.nip,
                    widget.otp,
                    _passwordController.text,
                    _confirmPasswordController.text,
                  );
                },
                isLoading: state.isLoading,
                icon: Icons.save_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
