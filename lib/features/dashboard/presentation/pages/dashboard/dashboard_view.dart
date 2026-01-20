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

              // 3. Service Menu (Pinned to Bottom, Behind Glass)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ServiceMenu(),
              ),

              // 4. Main Content (Draggable/Scrollable or just Overflowing)
              Consumer(
                builder: (context, ref, child) {
                  final userState = ref.watch(userProvider);
                  final user = userState.currentUser;

                  // Use SafeArea to avoid notches
                  return SafeArea(
                    bottom:
                        false, // Allow content to reach bottom (overlap menu)
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Distribute top/mid/bottom
                      children: [
                        // Header with User Card
                        DashboardHeader(
                          user: user,
                          onLogout: () => controller.logout(),
                        ),

                        // Banner Slider (Reduced Height 150)
                        const SizedBox(height: 10),
                        const BannerSlider(),
                        const SizedBox(height: 10),

                        // MAIN GLASS PANE (Expanded to fill available space)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 2.0,
                                  sigmaY: 2.0,
                                ), // Very subtle blur
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        0.3,
                                      ), // Slightly lighter border too
                                      width: 1.5,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(
                                          0.03,
                                        ), // Very transparent
                                        Colors.black.withOpacity(
                                          0.01,
                                        ), // Almost clear
                                      ],
                                      stops: const [0.2, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          0.3,
                                        ), // Depth 52
                                        blurRadius: 30,
                                        offset: const Offset(0, 20),
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Content: Clock & Button (Centered)
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // 1. Time & Location
                                          const ActionStatusCard(),
                                          // 2. Button & Info
                                          const AttendanceActions(),
                                          // Spacer for Glow Bar area
                                          const SizedBox(height: 20),
                                        ],
                                      ),

                                      // 3. Glow Bar (Pinned ABSOLUTELY at bottom)
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 4,
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical:
                                                12, // Reduced to move bar lower
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.cyanAccent.withOpacity(
                                                  0.0,
                                                ),
                                                Colors.white.withOpacity(0.8),
                                                Colors.cyanAccent.withOpacity(
                                                  0.0,
                                                ),
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.cyanAccent
                                                    .withOpacity(0.6),
                                                blurRadius: 15,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 0),
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

                        // Spacing at bottom to ensure GlassPane overlaps ServiceMenu
                        // This pushes the bottom of GlassPane UP from the absolute screen bottom.
                        // If ServiceMenu is ~150px tall (ScreenH - 150).
                        // We want GlassPane to end at (ScreenH - 110).
                        const SizedBox(height: 140),
                      ],
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
