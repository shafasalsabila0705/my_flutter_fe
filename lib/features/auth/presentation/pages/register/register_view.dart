import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../../../injection_container.dart';
import '../../../../../core/constants/strings.dart';
import '../../widgets/auth_header.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import 'register_controller.dart';

class RegisterView extends fca.View {
  const RegisterView({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterViewState();
}

class _RegisterViewState
    extends fca.ViewState<RegisterView, RegisterController> {
  _RegisterViewState() : super(sl<RegisterController>());

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        title: const Text('Registrasi Akun'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: fca.ControlledWidgetBuilder<RegisterController>(
        builder: (context, controller) {
          return Center(
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

                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // NIP Field
                  CustomTextField(
                    controller: controller.nipController,
                    label: 'Nomor Induk Pegawai',
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  CustomTextField(
                    controller: controller.nameController,
                    label: 'Nama Lengkap',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  CustomTextField(
                    controller: controller.emailController,
                    label: 'Email ',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  CustomTextField(
                    controller: controller.phoneController,
                    label: 'No. HP ',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: controller.passwordController,
                    label: 'Kata Sandi',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    controller: controller.confirmPasswordController,
                    label: 'Konfirmasi Kata Sandi',
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  CustomButton(
                    text: 'Daftar',
                    onPressed: controller.register,
                    isLoading: controller.isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Back to Login Link
                  TextButton(
                    onPressed: controller.navigateToLogin,
                    child: const Text('Sudah punya akun? Login disini'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
