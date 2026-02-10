import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/custom_text_field.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../widgets/auth_header.dart';
import '../../providers/otp_verification_notifier.dart';
import '../../providers/forgot_password_notifier.dart';
import 'reset_password_page.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String nip;
  const OtpVerificationPage({super.key, required this.nip});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerificationProvider);
    final notifier = ref.read(otpVerificationProvider.notifier);

    ref.listen(otpVerificationProvider, (previous, next) {
      if (next.successMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordPage(nip: widget.nip, otp: _otpController.text),
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

    ref.listen(forgotPasswordProvider, (previous, next) {
      if (next.successMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("OTP berhasil dikirim ulang"),
            backgroundColor: Colors.green,
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
                title: "Verifikasi OTP",
                subtitle: "Masukkan Kode Verifikasi",
                version: "",
              ),
              const SizedBox(height: 40),

              Text(
                "Masukkan kode OTP yang dikirim ke email untuk NIP ${widget.nip}.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _otpController,
                label: "Kode OTP",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: "Verifikasi",
                onPressed: () {
                  notifier.verifyOtp(widget.nip, _otpController.text);
                },
                isLoading: state.isLoading,
                icon: Icons.verified_user_rounded,
              ),

              const SizedBox(height: 24),

              // Resend Config
              if (_canResend)
                TextButton(
                  onPressed: () {
                    // Trigger Resend
                    ref
                        .read(forgotPasswordProvider.notifier)
                        .requestOtp(widget.nip);
                    startTimer();
                  },
                  child: const Text(
                    "Kirim Ulang OTP",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  "Kirim ulang dalam 00:${_start.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

              const SizedBox(height: 24),

              // Back Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Kembali",
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
