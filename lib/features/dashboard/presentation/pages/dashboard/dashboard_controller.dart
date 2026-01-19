import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../../../core/providers/user_provider.dart';

import 'dashboard_presenter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardController extends Controller {
  final DashboardPresenter _presenter;

  DashboardController(this._presenter);

  // UserProvider get userProvider => sl<UserProvider>(); // REMOVED

  @override
  void initListeners() {
    // No specific listeners for now
  }

  void logout() {
    // Clear Global State (Riverpod)
    try {
      ProviderScope.containerOf(
        getContext(),
        listen: false,
      ).read(userProvider.notifier).clearUser();
    } catch (e) {
      print('Riverpod Error: $e');
    }

    // Navigate back to login and remove all previous routes
    Navigator.of(getContext()).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
