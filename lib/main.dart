import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/login/login_view.dart';
import 'features/auth/presentation/pages/register/register_view.dart';
import 'features/dashboard/presentation/pages/dashboard/dashboard_view.dart';
import 'injection_container.dart' as di;

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clean Architecture',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginView(),
      routes: {
        '/register': (context) => const RegisterView(),
        '/dashboard': (context) => const DashboardView(),
      },
    );
  }
}
