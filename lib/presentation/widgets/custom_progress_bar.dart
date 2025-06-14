import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color backgroundColor;
  final Gradient gradient;
  final double borderRadius;
  const CustomProgressBar({
    required this.value,
    this.height = 12,
    this.backgroundColor = const Color(0xFF23262F),
    this.gradient = const LinearGradient(
      colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    this.borderRadius = 8,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Container(height: height, color: backgroundColor),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            height: height,
            width: MediaQuery.of(context).size.width * value,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ],
      ),
    );
  }
}
