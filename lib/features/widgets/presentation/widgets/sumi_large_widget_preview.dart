import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sumi_app/features/widgets/data/sumi_widget_entry.dart';

class SumiLargeWidgetPreview extends StatelessWidget {
  final SumiWidgetEntry entry;

  const SumiLargeWidgetPreview({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 329,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/sumi_logo_light.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_stories,
                  color: Color(0xFFFF4F6D),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Today in Sumi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.subtitle,
            style: const TextStyle(
              color: Color(0xFFFF4F6D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...entry.updates.map(
            (update) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 36,
                      height: 48,
                      child: update.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: update.coverUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _coverPlaceholder,
                            )
                          : _coverPlaceholder,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.mangaTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${update.chapterLabel} \u00b7 ${update.timeAgo}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _coverPlaceholder => Container(
        color: const Color(0xFF151B23),
      );
}
