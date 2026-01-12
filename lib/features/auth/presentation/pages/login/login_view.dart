import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../../../core/constants/strings.dart';
import '../../../../../injection_container.dart';
import 'package:lottie/lottie.dart';
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
                  // Illustration Replacement (Icon for safety as Asset setup requires restart & config)
                  // Illustration (Lottie Animation)
                  Lottie.asset(
                    'assets/animations/logo_registerlogin.json',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    AppStrings.loginTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.ssoTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Text(
                    AppStrings.version,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  TextField(
                    controller: controller.nipController,
                    decoration: InputDecoration(
                      labelText: AppStrings.nipLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: controller.passwordController,
                    decoration: InputDecoration(
                      labelText: AppStrings.passwordLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isLoading ? null : controller.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Match design blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login),
                                SizedBox(width: 8),
                                Text(AppStrings.loginButton),
                              ],
                            ),
                    ),
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
