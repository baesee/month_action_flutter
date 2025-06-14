import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final Gradient gradient;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  const GradientButton({
    required this.child,
    this.onTap,
    this.height = 52,
    this.borderRadius = 18,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.margin,
    this.padding,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: height,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
