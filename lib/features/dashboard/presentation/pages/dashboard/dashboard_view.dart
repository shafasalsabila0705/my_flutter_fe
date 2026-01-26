import 'dart:ui'; // Add for ImageFilter

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
          key: globalKey,
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
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 3. Main Content (Scrolls + Fills)
              Consumer(
                builder: (context, ref, child) {
                  // final userState = ref.watch(userProvider); // Moved to new Consumer
                  // final user = userState.currentUser; // Moved to new Consumer

                  return SafeArea(
                    bottom: false,
                    child: CustomScrollView(
                      slivers: [
                        // 1. Banner (Scrollable Content)
                        SliverToBoxAdapter(
                          child: Stack(
                            children: [
                              // Layer 1: Banner (Pushed down by fixed amount to show below collapsed header)
                              Column(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.top +
                                        110,
                                  ),
                                  BannerSlider(
                                    banners: controller.banners,
                                    isLoading: controller.isLoadingBanners,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),

                              // Layer 2: Header (Expands and covers banner)
                              // Not Positioned: ensures it contributes to Stack size, making it clickable
                              // DashboardHeader( // Removed from here
                              //   user: user,
                              //   onLogout: () => controller.logout(),
                              // ),
                            ],
                          ),
                        ),

                        // 2. Glass Pane + Service Menu (Fills remaining space or scrolls)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Stack(
                            children: [
                              // Layer 1: Service Menu (Visually at the bottom, Lower Z-Index)
                              const Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: ServiceMenu(),
                              ),

                              // Layer 2: Glass Pane Scope (Higher Z-Index)
                              Column(
                                children: [
                                  // Glass Pane - Expands to push down
                                  Expanded(
                                    child: Transform.translate(
                                      offset: const Offset(
                                        0,
                                        10,
                                      ), // Overlaps white shape, but higher than original 20
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                      0.03,
                                                    ),
                                                    Colors.black.withOpacity(
                                                      0.01,
                                                    ),
                                                  ],
                                                  stops: const [0.2, 1.0],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const ActionStatusCard(),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      AttendanceActions(
                                                        onCheckIn:
                                                            (lat, long) =>
                                                                controller
                                                                    .checkIn(
                                                                      lat,
                                                                      long,
                                                                    ),
                                                        onCheckOut:
                                                            (lat, long) =>
                                                                controller
                                                                    .checkOut(
                                                                      lat,
                                                                      long,
                                                                    ),
                                                        initialData: controller
                                                            .todayAttendance,
                                                      ),
                                                      const SizedBox(
                                                        height: 25,
                                                      ),
                                                    ],
                                                  ),
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
                                                                .withOpacity(
                                                                  0.0,
                                                                ),
                                                            Colors.white
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                            Colors.cyanAccent
                                                                .withOpacity(
                                                                  0.0,
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
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
                                                            blurRadius: 15,
                                                            spreadRadius: 1,
                                                            offset:
                                                                const Offset(
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
                                  // Takes up space so the Column knows where to stop expanding
                                  // Allows scrolling to work correctly
                                  Opacity(
                                    opacity: 0,
                                    // IgnorePointer ensures touches pass through to the real ServiceMenu below
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
                  );
                },
              ),

              // 4. Fixed Header Overlay
              Consumer(
                builder: (context, ref, child) {
                  final userState = ref.watch(userProvider);
                  final user = userState.currentUser;

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DashboardHeader(
                      user: user,
                      onLogout: () => controller.logout(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
