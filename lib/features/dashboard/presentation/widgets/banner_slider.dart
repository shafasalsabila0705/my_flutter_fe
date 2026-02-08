import 'package:flutter/material.dart';
import 'dart:async';

import '../../data/models/banner_model.dart';

class BannerSlider extends StatefulWidget {
  final List<BannerModel>? banners;
  final bool isLoading;

  const BannerSlider({super.key, this.banners, this.isLoading = false});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController(
    viewportFraction: 0.7,
    initialPage: 1000, // Large number for infinite scroll
  );
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (widget.banners == null || widget.banners!.isEmpty) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Tidak ada info terbaru",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            padEnds: true,
            // itemCount: null, // Infinite
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % widget.banners!.length;
              });
            },
            itemBuilder: (context, index) {
              // Modulo for infinite loop
              final int realIndex = index % widget.banners!.length;
              final banner = widget.banners![realIndex];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  } else {
                    // Approximate logic for initial state or jump
                    final double dist = (index - _pageController.initialPage)
                        .toDouble();
                    if (dist.abs() < 1) {
                      value = 1.0;
                    } else {
                      value = 0.7;
                    }
                  }

                  final double scale = Curves.easeInOut
                      .transform(value)
                      .clamp(0.8, 1.0);

                  final double opacity = Curves.easeIn
                      .transform(value)
                      .clamp(0.6, 1.0);

                  final bool isFocused = value > 0.9;

                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Image
                                Image.network(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                // Focused Overlay
                                if (!isFocused)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners!.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                boxShadow: _currentPage == index
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}
