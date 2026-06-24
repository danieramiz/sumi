import 'package:flutter/material.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_entry.dart';

class SumiSmallWidgetPreview extends StatelessWidget {
  final SumiWidgetEntry entry;

  const SumiSmallWidgetPreview({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/sumi_logo_light.png',
            width: 36,
            height: 36,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.auto_stories,
              color: Color(0xFFFF4F6D),
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.newChapterCount} new chapters',
            style: const TextStyle(
              color: Color(0xFFFF4F6D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
