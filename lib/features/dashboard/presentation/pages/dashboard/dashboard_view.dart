import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as fca;
import '../../../../../../injection_container.dart';
import 'dashboard_controller.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/banner_slider.dart';
import '../../widgets/attendance_actions.dart';
import '../../widgets/service_menu.dart';
import '../../widgets/action_status_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';

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
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8), // Light grey background
          body: Consumer(
            builder: (context, ref, child) {
              final userState = ref.watch(userProvider);
              final user = userState.currentUser;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header with User Card (overlapping)
                    DashboardHeader(
                      user: user,
                      onLogout: () => controller.logout(),
                    ),

                    // Spacing for overlapping user card
                    const SizedBox(height: 30),

                    // Banner Slider
                    const BannerSlider(),
                    const SizedBox(height: 24),

                    // Location & Time Status Card
                    const ActionStatusCard(),
                    const SizedBox(height: 24),

                    // Clock In Button & Attendance Info
                    const AttendanceActions(),
                    const SizedBox(height: 8), // Minimal spacing
                    // Service Menu (Layanan Kepegawaian)
                    const ServiceMenu(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
