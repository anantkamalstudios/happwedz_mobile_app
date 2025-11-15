import 'package:flutter/material.dart';

class LoadingLogo extends StatefulWidget {
  final double size;
  final Duration speed;
  final VoidCallback? onFinish;     // 🔥 callback after rotation

  const LoadingLogo({
    super.key,
    this.size = 120,
    this.speed = const Duration(seconds: 3),
    this.onFinish,
  });

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.speed,
      vsync: this,
    );

    // 🔥 Detect when animation ends
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onFinish != null) {
          widget.onFinish!();   // notify parent to hide loader
        }
      }
    });

    _controller.forward(); // start rotation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
          ),
        ),
        child: Image.asset(
          "assets/logo.png",
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}
