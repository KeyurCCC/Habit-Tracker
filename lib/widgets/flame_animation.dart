import 'package:flutter/material.dart';

class FlameAnimation extends StatefulWidget {
  final double size;
  final Color color;
  const FlameAnimation({super.key, this.size = 20, this.color = const Color(0xFFFF6B6B)});

  @override
  State<FlameAnimation> createState() => _FlameAnimationState();
}

class _FlameAnimationState extends State<FlameAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.local_fire_department,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
