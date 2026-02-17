import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/attendance_model.dart'; // Import model for Completer
import '../../../../../../core/providers/user_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/banner_slider.dart';
import '../../widgets/attendance_actions.dart';
import '../../widgets/service_menu.dart';
import '../../widgets/action_status_card.dart';
import '../../providers/dashboard_notifier.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboardData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 Dashboard: App resumed, refreshing data...");
      ref.read(dashboardProvider.notifier).loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final userState = ref.watch(userProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    final user = userState.currentUser;

    // Listen to User State changes for Logout
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser != null && next.currentUser == null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });

    // Listen to Dashboard State errors
    ref.listen(dashboardProvider, (previous, next) {
      // Only show if error is new or changed and not null
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/img/balaikotabaru.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A1A2E), // Fallback dark color
              ),
            ),
          ),

          // 2. Dark Gradient Overlay for Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // A. Scrollable Content
                RefreshIndicator(
                  onRefresh: () async {
                    notifier.loadDashboardData();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: CustomScrollView(
                    slivers: [
                      // 1. Header & Banner
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // 1.1 Header Placeholder with Link
                            CompositedTransformTarget(
                              link: _layerLink,
                              child: DashboardHeader(
                                user: user,
                                onLogout: () {},
                                isPlaceholder: true,
                              ),
                            ),

                            // 1.2 Banner
                            BannerSlider(
                              banners: dashboardState.banners,
                              isLoading:
                                  dashboardState.isLoading &&
                                  dashboardState.banners.isEmpty,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // 2. Glass Pane + Service Menu
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Stack(
                          children: [
                            // Layer 1: Service Menu
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: ServiceMenu(),
                            ),

                            // Layer 2: Glass Pane
                            Column(
                              children: [
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 2.0,
                                            sigmaY: 2.0,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                                width: 1.5,
                                              ),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.03,
                                                  ),
                                                  Colors.black.withValues(
                                                    alpha: 0.01,
                                                  ),
                                                ],
                                                stops: const [0.2, 1.0],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 30,
                                                  offset: const Offset(0, 20),
                                                  spreadRadius: -5,
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    ActionStatusCard(
                                                      locationName: dashboardState
                                                          .currentLocationName,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    AttendanceActions(
                                                      onValidateSchedule: () =>
                                                          notifier
                                                              .validateSchedule(),
                                                      onCheckIn:
                                                          (
                                                            lat,
                                                            long, {
                                                            reason,
                                                          }) {
                                                            final completer =
                                                                Completer<
                                                                  AttendanceModel
                                                                >();
                                                            notifier.checkIn(
                                                              lat,
                                                              long,
                                                              reason: reason,
                                                              onSuccess: (m) =>
                                                                  completer
                                                                      .complete(
                                                                        m,
                                                                      ),
                                                              onError: (e) =>
                                                                  completer
                                                                      .completeError(
                                                                        e,
                                                                      ),
                                                            );
                                                            return completer
                                                                .future;
                                                          },
                                                      onCheckOutWithPhoto:
                                                          (
                                                            photo,
                                                            lat,
                                                            long, {
                                                            reason,
                                                          }) {
                                                            final completer =
                                                                Completer<
                                                                  AttendanceModel
                                                                >();
                                                            notifier.checkOut(
                                                              lat,
                                                              long,
                                                              photo: photo,
                                                              reason: reason,
                                                              onSuccess: (m) =>
                                                                  completer
                                                                      .complete(
                                                                        m,
                                                                      ),
                                                              onError: (e) =>
                                                                  completer
                                                                      .completeError(
                                                                        e,
                                                                      ),
                                                            );
                                                            return completer
                                                                .future;
                                                          },
                                                      onCheckOut:
                                                          (
                                                            lat,
                                                            long, {
                                                            reason,
                                                          }) {
                                                            final completer =
                                                                Completer<
                                                                  AttendanceModel
                                                                >();
                                                            notifier.checkOut(
                                                              lat,
                                                              long,
                                                              reason: reason,
                                                              onSuccess: (m) =>
                                                                  completer
                                                                      .complete(
                                                                        m,
                                                                      ),
                                                              onError: (e) =>
                                                                  completer
                                                                      .completeError(
                                                                        e,
                                                                      ),
                                                            );
                                                            return completer
                                                                .future;
                                                          },
                                                      initialData:
                                                          dashboardState
                                                              .todayAttendance,
                                                      isOutsideRadius:
                                                          dashboardState
                                                              .isOutsideRadius,
                                                      onCheckInWithPhoto:
                                                          (
                                                            photo,
                                                            lat,
                                                            long, {
                                                            reason,
                                                          }) {
                                                            final completer =
                                                                Completer<
                                                                  AttendanceModel
                                                                >();
                                                            notifier.checkIn(
                                                              lat,
                                                              long,
                                                              photo: photo,
                                                              reason: reason,
                                                              onSuccess: (m) =>
                                                                  completer
                                                                      .complete(
                                                                        m,
                                                                      ),
                                                              onError: (e) =>
                                                                  completer
                                                                      .completeError(
                                                                        e,
                                                                      ),
                                                            );
                                                            return completer
                                                                .future;
                                                          },
                                                    ),
                                                    const SizedBox(height: 25),
                                                  ],
                                                ),

                                                // Decorative Bottom Line
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    height: 4,
                                                    width: double.infinity,
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 32,
                                                          vertical: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.cyanAccent
                                                              .withValues(
                                                                alpha: 0.0,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                          Colors.cyanAccent
                                                              .withValues(
                                                                alpha: 0.0,
                                                              ),
                                                        ],
                                                        stops: const [
                                                          0.0,
                                                          0.5,
                                                          1.0,
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors
                                                              .cyanAccent
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                          blurRadius: 15,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Invisible Service Menu Placeholder to clear space for Positoned ServiceMenu
                                Visibility(
                                  visible: false,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: IgnorePointer(
                                    child: const ServiceMenu(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // B. Floating Header (Overlay)
                Positioned(
                  top: 0,
                  left: 0,
                  width: MediaQuery.of(context).size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset.zero,
                    child: DashboardHeader(
                      user: user,
                      onLogout: () => notifier.logout(),
                    ),
                  ),
                ),

                // C. Loading Overlay
                if (dashboardState.isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
