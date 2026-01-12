import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../../../core/providers/user_provider.dart';
import '../../../../../../injection_container.dart';
import 'dashboard_presenter.dart';

class DashboardController extends Controller {
  final DashboardPresenter _presenter;

  DashboardController(this._presenter);

  UserProvider get userProvider => sl<UserProvider>();

  @override
  void initListeners() {
    // No specific listeners for now
  }

  void logout() {
    userProvider.clearUser();
    // Navigate back to login and remove all previous routes
    Navigator.of(getContext()).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
