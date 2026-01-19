import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../../../core/constants/strings.dart';
import '../../../../../injection_container.dart';

import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../widgets/auth_header.dart';
import 'login_controller.dart';

class LoginView extends fca.View {
  const LoginView({super.key});

  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

class _LoginViewState extends fca.ViewState<LoginView, LoginController> {
  _LoginViewState() : super(sl<LoginController>());

  @override
  Widget get view {
    // Assuming image is saved in assets or we load from file for this environment
    // For this environment, since I used generate_image and I can't add to assets easily:
    // I will try to load from local file if mostly Windows/Desktop or placeholder.
    // Ideally user adds to pubspec.yaml assets.
    // For now I will use a placeholder Icon if image load fails or just Icon to be safe,
    // unless I can use FileImage with absolute path which is risky for production but okay for this debug.
    // Better: Use a nice Icon or generic asset.
    // The user has the generated image on disk. I will use it.
    // Path: C:\Users\HP\.gemini\antigravity\brain\aa5fc007-1285-4f7a-971f-bb1747bd2897\login_illustration_1768193884278.png
    // In valid Flutter app, this must be in assets. I'll use a placeholder Icon to be safe and cleaner code,
    // OR create a custom widget that tries to load it.
    // I'll stick to a high quality Icon similar to the illustration concept.

    return Scaffold(
      key: globalKey,
      backgroundColor: Colors.white,
      body: fca.ControlledWidgetBuilder<LoginController>(
        builder: (context, controller) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Auth Header
                  const AuthHeader(
                    title: AppStrings.loginTitle,
                    subtitle: AppStrings.ssoTitle,
                    version: AppStrings.version,
                  ),

                  const SizedBox(height: 48),

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
                    label: AppStrings.nipLabel,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: controller.passwordController,
                    label: AppStrings.passwordLabel,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  CustomButton(
                    text: AppStrings.loginButton,
                    onPressed: controller.login,
                    isLoading: controller.isLoading,
                    icon: Icons.login,
                  ),

                  const SizedBox(height: 24),

                  // Register Link
                  TextButton(
                    onPressed: controller.navigateToRegister,
                    child: const Text('Belum punya akun? Daftar disini'),
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
