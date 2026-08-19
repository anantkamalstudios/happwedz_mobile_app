
import 'dart:async';

import 'package:flutter/material.dart';

import 'core/core.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Assets floating along the top edge.
  static const List<String> _topImages = [
    'assets/Splash1.png',
    'assets/Splash2.png',
    'assets/Splash3.png',
    'assets/Splash4.png',
  ];

  /// Assets floating along the bottom edge.
  static const List<String> _bottomImages = [
    'assets/Splash5.png',
    'assets/Splash6.png',
    'assets/Splash7.png',
    'assets/Splash3.png',
  ];




  late final AnimationController _logoController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _floatController;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _logoController.forward();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Navigation — unchanged destination, now guarded against a disposed state.
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AnimatedPageRoute(
          page: const AuthGate(),
          style: PageTransitionStyle.fade,
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  /// A single bobbing asset. [size] is derived from the viewport so the row
  /// never overflows on small phones.
  Widget _floatingImage(
    String asset,
    double baseRotation,
    double offsetY,
    double size,
  ) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final t = _floatController.value;
        return Opacity(
          opacity: 0.6 + (t * 0.4),
          child: Transform.translate(
            offset: Offset(0, offsetY + (t * 12)),
            child: Transform.rotate(
              angle: baseRotation + (t * 0.12),
              child: child,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: AppRadii.rMd,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Lays the four assets out evenly without ever exceeding the width.
  Widget _floatingRow(
    List<String> assets,
    List<double> rotations,
    List<double> offsets,
    double tileSize,
    double gap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < assets.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          _floatingImage(assets[i], rotations[i], offsets[i], tileSize),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Four tiles + three gaps + outer padding must fit the width.
          const count = 4;
          const gap = AppSpacing.sm;
          const horizontalPadding = AppSpacing.md;
          final available =
              width - (horizontalPadding * 2) - (gap * (count - 1));
          final tileSize = (available / count).clamp(48.0, 90.0);

          final logoWidth = (width * 0.32).clamp(88.0, 140.0);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: height * 0.06,
                    left: 0,
                    right: 0,
                    child: _floatingRow(
                      _topImages,
                      const [-0.15, 0.10, -0.05, 0.08],
                      const [0, 15, 0, 10],
                      tileSize,
                      gap,
                    ),
                  ),

                  Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/logo.png', width: logoWidth),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'HAPPY WEDZ',
                              textAlign: TextAlign.center,
                              style: AppText.sectionTitle.copyWith(
                                color: AppColors.textOnPrimary,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: height * 0.05,
                    left: 0,
                    right: 0,
                    child: _floatingRow(
                      _bottomImages,
                      const [-0.05, 0.10, -0.15, 0.12],
                      const [0, 10, 0, 8],
                      tileSize,
                      gap,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}