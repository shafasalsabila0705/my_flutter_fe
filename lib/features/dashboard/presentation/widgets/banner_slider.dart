import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController(
    viewportFraction: 0.7, // Shows center + peeking sides better
    initialPage: 1000,
  );
  int _currentPage = 1000;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150, // Increased slightly per user request
          child: PageView.builder(
            controller: _pageController,
            padEnds: true,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  } else {
                    value = index == _currentPage ? 1.0 : 0.7;
                  }

                  // value is 1.0 at center, drops to 0.7 at sides.
                  // We want distinct states.
                  final double scale = Curves.easeInOut
                      .transform(value)
                      .clamp(
                        0.8,
                        1.0,
                      ); // 0.8 side, 1.0 center (Balanced difference)

                  // Also apply opacity for depth
                  final double opacity = Curves.easeIn
                      .transform(value)
                      .clamp(0.6, 1.0);
                  // Define isFocused for logic
                  final bool isFocused = value > 0.9;

                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                          ), // Add spacing
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
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
                                // Design Requirement: "Banner fokus putih"
                                Container(
                                  color: Colors.white,
                                  child: isFocused
                                      ? null
                                      : Container(
                                          color: Colors.black.withOpacity(0.1),
                                        ), // Dim sides slightly
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
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: (_currentPage % 3) == index
                  ? 24
                  : 8, // Elongated active dot
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: (_currentPage % 3) == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                boxShadow: (_currentPage % 3) == index
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
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
