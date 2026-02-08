import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/strings.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../providers/register_notifier.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nipController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final notifier = ref.read(registerProvider.notifier);

    ref.listen(registerProvider, (previous, next) {
      if (next.successMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Back to Login
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
      appBar: AppBar(
        title: const Text('Registrasi Akun'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Auth Header
              const AuthHeader(
                title: AppStrings.ssoTitle,
                subtitle: 'Kota Padang',
              ),
              const SizedBox(height: 32),

              if (registerState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    registerState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // NIP Field
              CustomTextField(
                controller: _nipController,
                label: 'Nomor Induk Pegawai',
              ),
              const SizedBox(height: 16),

              // Name Field
              CustomTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Email Field
              CustomTextField(
                controller: _emailController,
                label: 'Email ',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Field
              CustomTextField(
                controller: _phoneController,
                label: 'No. HP ',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                controller: _passwordController,
                label: 'Kata Sandi',
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Konfirmasi Kata Sandi',
                isPassword: true,
              ),
              const SizedBox(height: 32),

              // Register Button
              CustomButton(
                text: 'Daftar',
                onPressed: () {
                  notifier.register(
                    nip: _nipController.text,
                    name: _nameController.text,
                    password: _passwordController.text,
                    confirmPassword: _confirmPasswordController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                  );
                },
                isLoading: registerState.isLoading,
              ),

              const SizedBox(height: 24),

              // Back to Login Link
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Sudah punya akun? Login disini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
