import 'package:flutter/material.dart';

class ButtonLoadingIndicator extends StatelessWidget {
  final double height;
  final double width;
  final double strokeWidth;
  final Color color;

  const ButtonLoadingIndicator({
    super.key,
    this.height = 20,
    this.width = 20,
    this.strokeWidth = 2,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, valueColor: AlwaysStoppedAnimation<Color>(color)),
    );
  }
}
