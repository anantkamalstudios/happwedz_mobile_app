import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Page transition styles available to [AnimatedPageRoute].
enum PageTransitionStyle { fade, slideUp, slideRight, scaleFade }

/// Reusable route with a short, tasteful transition.
///
/// Usage: `Navigator.push(context, AnimatedPageRoute(page: const Foo()))`
/// It is a drop-in replacement for MaterialPageRoute — navigation behaviour,
/// results and back handling are unchanged.
class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  AnimatedPageRoute({
    required this.page,
    this.style = PageTransitionStyle.slideUp,
    this.duration = AppMotion.slow,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: AppMotion.normal,
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.standard,
              reverseCurve: AppMotion.exit,
            );

            switch (style) {
              case PageTransitionStyle.fade:
                return FadeTransition(opacity: curved, child: child);

              case PageTransitionStyle.slideUp:
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );

              case PageTransitionStyle.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.15, 0),
                    end: Offset.zero,
                  ).animate(curved),
                  child: FadeTransition(opacity: curved, child: child),
                );

              case PageTransitionStyle.scaleFade:
                return FadeTransition(
                  opacity: curved,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                    child: child,
                  ),
                );
            }
          },
        );

  final Widget page;
  final PageTransitionStyle style;
  final Duration duration;
}

/// Convenience helpers so screens read cleanly.
extension AppNavigation on BuildContext {
  Future<T?> pushPage<T>(
    Widget page, {
    PageTransitionStyle style = PageTransitionStyle.slideUp,
  }) {
    return Navigator.of(this).push<T>(
      AnimatedPageRoute<T>(page: page, style: style),
    );
  }

  Future<T?> pushReplacementPage<T, TO>(
    Widget page, {
    PageTransitionStyle style = PageTransitionStyle.fade,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      AnimatedPageRoute<T>(page: page, style: style),
    );
  }
}

/// Fades and slides its child in once, on first build.
///
/// Used for list items, cards and empty/error states. Cheap: a single
/// AnimationController per item, disposed with the widget.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    this.offset = const Offset(0, 0.08),
    this.curve = AppMotion.standard,
    this.enabled = true,
  });

  /// Staggered constructor for list/grid items.
  FadeSlideIn.staggered({
    super.key,
    required this.child,
    required int index,
    this.duration = AppMotion.normal,
    this.offset = const Offset(0, 0.08),
    this.curve = AppMotion.standard,
    this.enabled = true,
  }) : delay = AppMotion.staggerFor(index);

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final bool enabled;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Expands/collapses its child with a size + fade animation.
class AppExpandable extends StatelessWidget {
  const AppExpandable({
    super.key,
    required this.expanded,
    required this.child,
    this.duration = AppMotion.normal,
  });

  final bool expanded;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: expanded ? 1 : 0,
        duration: duration,
        curve: AppMotion.standard,
        child: expanded
            ? child
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }
}
