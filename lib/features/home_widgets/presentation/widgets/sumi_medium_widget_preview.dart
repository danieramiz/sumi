import 'package:flutter/material.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_entry.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/widget_cover_background.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/widget_progress_bar.dart';

class SumiMediumWidgetPreview extends StatelessWidget {
  final SumiWidgetEntry entry;

  const SumiMediumWidgetPreview({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 329,
      height: 159,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
      ),
      child: WidgetCoverBackground(
        imageUrl: entry.coverUrl,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xB3000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (entry.chapterLabel != null) ...[
                        Text(
                          entry.chapterLabel!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 10,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (entry.progress != null)
                        Text(
                          '${(entry.progress! * 100).round()}% caught up',
                          style: const TextStyle(
                            color: Color(0xFFFF4F6D),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  WidgetProgressBar(
                    progress: entry.progress ?? 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
