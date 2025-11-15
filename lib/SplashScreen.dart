import 'package:flutter/material.dart';
import 'dart:async';

import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    // LOGO SCALE ANIMATION
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));
    _logoController.forward();

    // FLOATING IMAGES CONTINUOUS LOOP
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Navigation
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ------------- ANIMATED FLOATING IMAGE -------------
  Widget animatedFloatingImage(String img, double baseRotation, double offsetY) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        double t = _floatController.value;

        return Opacity(
          opacity: 0.6 + (t * 0.4), // fade effect
          child: Transform.translate(
            offset: Offset(0, offsetY + (t * 12)), // smooth bobbing
            child: Transform.rotate(
              angle: baseRotation + (t * 0.12), // slight rotation
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  img,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe91e63),

      body: Stack(
        children: [

          // ---------- TOP IMAGES ----------
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                animatedFloatingImage("assets/Splash1.png", -0.15, 0),
                animatedFloatingImage("assets/Splash2.png", 0.10, 15),
                animatedFloatingImage("assets/Splash3.png", -0.05, 0),
                animatedFloatingImage("assets/Splash4.png", 0.08, 10), // new image
              ],
            ),
          ),

          // ---------- CENTER LOGO ----------
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/logo.png", width: 120),
                  const SizedBox(height: 12),
                  const Text(
                    "HAPPY WEDZ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- BOTTOM IMAGES ----------
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                animatedFloatingImage("assets/Splash5.png", -0.05, 0),
                animatedFloatingImage("assets/Splash6.png", 0.10, 10),
                animatedFloatingImage("assets/Splash7.png", -0.15, 0),
                animatedFloatingImage("assets/Splash3.png", 0.12, 8), // new image
              ],
            ),
          ),
        ],
      ),
    );
  }
}
