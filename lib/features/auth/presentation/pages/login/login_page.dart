import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../../core/widgets/custom_text_field.dart';
import '../../widgets/auth_header.dart';
import '../../providers/login_notifier.dart';
import '../forgot_password/forgot_password_page.dart';
import '../../../../../core/providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // We can keep controllers local to the UI or put them in the notifier.
  // Since they are UI TextEdittingControllers, keeping them here is fine and often preferred.
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with saved values if any (Notifier handles loading logic but we need to populate controllers)
    // Actually, Notifier loads into its state or simple variables.
    // Let's check Notifier logic.
    // Notifier has _loadSavedCredentials which might run async.
    // It updates `initialNip` and `initialPassword` but updating TextEditingController from outside build is tricky.
    // Best practice: The inputs are driven by the user, but pre-filled by state.

    // We can listen to state changes or just check once.
    // Let's delay slightly to allow notifier to load (it started in constructor),
    // OR we can make Notifier expose specific state for this.
    // Simplified: Just clear controllers here, and rely on `ref.listen` to populate if remember me was found.
  }

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    // Listen to changes for Navigation or Toast or Remember Me Population
    ref.listen(loginProvider, (previous, next) {
      // Handle Success
      if (next.isSuccess && !next.isLoading) {
        // Update Global User Provider (if needed, although LoginUseCase might have done it,
        // usually Controller did it. Let's see logical flow).
        // LoginNotifier calls UseCase. UseCase returns User.
        // We need to put User into UserProvider (Riverpod).
        // We actually didn't put User into UserProvider in LoginNotifier yet!
        // I need to update LoginNotifier or do it here.
        // Better to do it in LoginNotifier or here. In Controller it was done in Observer.
        // I will do it here for now or update Notifier.
        // Wait, LoginNotifier Observer calls `_handleSuccess` but currently just sets state.
        // It DOES NOT update UserProvider. I should probably fix that in Notifier or here.
        // Cleanest: Notifier updates UserProvider. But Notifier needs Ref to read other providers.
        // So I should pass `Ref` to LoginNotifier or expose `User` in `LoginState` and listen here.
        // Missing Piece: LoginNotifier didn't save the User object in state!
        if (next.user != null) {
          ref.read(userProvider.notifier).setUser(next.user!);
        }

        Navigator.of(context).pushReplacementNamed('/dashboard');
      }

      // Handle Errors
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Handle Remember Me Population (One time)
      if (next.rememberMe && (previous == null || !previous.rememberMe)) {
        if (notifier.initialNip != null) {
          _nipController.text = notifier.initialNip!;
        }
        if (notifier.initialPassword != null) {
          _passwordController.text = notifier.initialPassword!;
        }
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
              // Auth Header
              const AuthHeader(
                title: AppStrings.loginTitle,
                subtitle: AppStrings.ssoTitle,
                version: AppStrings.version,
              ),

              const SizedBox(height: 48),

              if (loginState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    loginState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // NIP Field
              CustomTextField(
                controller: _nipController,
                label: AppStrings.nipLabel,
              ),
              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                controller: _passwordController,
                label: AppStrings.passwordLabel,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Remember Me
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 0.0,
                    ), // Align with text fields
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: loginState.rememberMe,
                        activeColor: const Color(0xFF29B6F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) =>
                            notifier.setRememberMe(val ?? false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => notifier.setRememberMe(!loginState.rememberMe),
                    child: Text(
                      "Ingat Saya",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Login Button
              CustomButton(
                text: AppStrings.loginButton,
                onPressed: () {
                  notifier.login(_nipController.text, _passwordController.text);
                },
                isLoading: loginState.isLoading,
                icon: Icons.login,
              ),

              const SizedBox(height: 24),

              // Forgot Password Link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text('Lupa Password?'),
              ),
              const SizedBox(height: 24),

              // Register Link
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: const Text('Belum punya akun? Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
