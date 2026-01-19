import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController(
    viewportFraction: 0.75, // Shows center + peeking sides
    initialPage: 1000,
  );
  int _currentPage = 1000;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            padEnds: true, // Center the current item
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              // Smooth animation wrapper
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    // Scale sides down to 0.7 (smaller peek), keep center at 1.0
                    value = (1 - (value.abs() * 0.4)).clamp(0.7, 1.0);
                  } else {
                    // Fallback for initial render
                    value = index == _currentPage ? 1.0 : 0.7;
                  }

                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 180,
                      width:
                          Curves.easeOut.transform(value) *
                          500, // Effectively max allowed by viewport
                      child: child,
                    ),
                  );
                },
                child: _buildBannerCard(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_currentPage % 3) == index
                    ? Colors.black87
                    : Colors.black26,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerCard(int index) {
    final isFocused = index == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(), // Placeholder
      ),
    );
  }
}
