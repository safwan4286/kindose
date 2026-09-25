import 'package:flutter/material.dart';

class BounceClick extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool callVoidCallbackFirst;

  const BounceClick({
    super.key,
    required this.child,
    this.onTap,
    this.callVoidCallbackFirst = false,
  });

  @override
  State<BounceClick> createState() => _BounceClickState();
}

class _BounceClickState extends State<BounceClick>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Quick bounce effect
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _bounce() async {
    if (widget.callVoidCallbackFirst) {
      if (widget.onTap != null) {
        widget.onTap!(); // Execute callback after animation
      }
    }

    await _controller.forward(); // Scale down
    await _controller.reverse(); // Scale back

    if (!widget.callVoidCallbackFirst) {
      if (widget.onTap != null) {
        widget.onTap!(); // Execute callback after animation
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _bounce, // Trigger bounce animation
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scale = 1 - _controller.value; // Scale calculation
          return Transform.scale(scale: scale, child: widget.child);
        },
      ),
    );
  }
}
