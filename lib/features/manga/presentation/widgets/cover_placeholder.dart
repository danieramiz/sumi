import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';

class CoverPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const CoverPlaceholder({
    super.key,
    this.width = 80,
    this.height = 110,
    this.borderRadius = AppRadius.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(Icons.auto_stories, color: AppColors.accent, size: 32),
      ),
    );
  }
}
