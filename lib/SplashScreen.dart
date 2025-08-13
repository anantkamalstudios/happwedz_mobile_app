import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:h_w_a/services/signup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Start animation
    _controller.forward();

    // Navigate to home screen after delay
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupPage()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect orientation
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fullscreen image
            Image.asset(
              'assets/images/logo2.webp',
              fit: isPortrait ? BoxFit.cover : BoxFit.fitHeight,
            ),

            // Brand name overlay
            Positioned(
              bottom: isPortrait ? 100 : 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Happy_Weds',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: isPortrait ? 32 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black12.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
