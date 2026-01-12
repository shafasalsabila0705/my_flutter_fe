import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../../../../injection_container.dart';
import 'dashboard_controller.dart';

class DashboardView extends fca.View {
  const DashboardView({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardViewState();
}

class _DashboardViewState
    extends fca.ViewState<DashboardView, DashboardController> {
  _DashboardViewState() : super(sl<DashboardController>());

  @override
  Widget get view {
    return fca.ControlledWidgetBuilder<DashboardController>(
      builder: (context, controller) {
        final user = controller.userProvider.currentUser;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => controller.logout(),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (user != null) ...[
                  Text(
                    'Nama: ${user.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NIP: ${user.nip}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ] else
                  const Text('User not found'),
              ],
            ),
          ),
        );
      },
    );
  }
}
