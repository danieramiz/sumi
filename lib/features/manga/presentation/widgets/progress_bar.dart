import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;

  const ProgressBar({super.key, required this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: AppColors.progressBg,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.accent),
        minHeight: 4,
      ),
    );
  }
}
