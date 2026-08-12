import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Wraps a child with a subtle press-scale micro-interaction.
///
/// Used by [PremiumButton], [AppCard] and any tappable tile so touch feedback
/// is consistent. Keeps the ripple (via the optional [InkWell] layer) while
/// adding the scale that makes the UI feel responsive.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.enabled = true,
    this.borderRadius,
    this.withRipple = false,
    this.rippleColor,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far the child shrinks while held. 1.0 disables the effect.
  final double scale;
  final bool enabled;
  final BorderRadius? borderRadius;

  /// When true an [InkWell] is layered on top for a Material ripple. Only use
  /// where the child paints an opaque surface, otherwise the splash is hidden.
  final bool withRipple;
  final Color? rippleColor;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setDown(bool value) {
    if (!_active || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedScale(
      scale: _down ? widget.scale : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: widget.child,
    );

    if (widget.withRipple) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: widget.borderRadius,
                splashColor: widget.rippleColor,
                onTap: _active ? widget.onTap : null,
                onLongPress: _active ? widget.onLongPress : null,
                onHighlightChanged: _setDown,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      );
      return content;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: _active ? widget.onTap : null,
      onLongPress: _active ? widget.onLongPress : null,
      child: content,
    );
  }
}
