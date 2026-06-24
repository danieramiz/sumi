import 'package:flutter/material.dart';

class WidgetProgressBar extends StatelessWidget {
  final double progress;
  final Color? activeColor;
  final Color? trackColor;

  const WidgetProgressBar({
    super.key,
    required this.progress,
    this.activeColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: trackColor ?? Colors.white.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(
            activeColor ?? const Color(0xFFFF4F6D),
          ),
        ),
      ),
    );
  }
}
