import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';

class FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const FloatingCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: AppColors.primaryText,
              size: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }
}
