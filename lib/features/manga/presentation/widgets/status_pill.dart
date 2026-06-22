import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color? customColor;

  const StatusPill({super.key, required this.label, this.customColor});

  @override
  Widget build(BuildContext context) {
    final color = customColor ?? _colorForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _colorForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'reading':
        return AppColors.reading;
      case 'on hold':
      case 'onhold':
        return AppColors.onHold;
      case 'completed':
        return AppColors.completed;
      case 'planned':
        return AppColors.planned;
      case 'dropped':
        return AppColors.dropped;
      case 'caught up':
      case 'caughtup':
        return AppColors.caughtUp;
      case 'new chapter':
      case 'newchapter':
        return AppColors.newChapter;
      default:
        return AppColors.accent;
    }
  }
}
