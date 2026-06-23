import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/core/utils/date_utils.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/cover_placeholder.dart';
import 'package:sumi_app/features/manga/presentation/widgets/soft_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/progress_bar.dart';

class MangaMasonryCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MangaMasonryCard({super.key, required this.manga, this.onTap, this.onLongPress});

  String get _statusLabel {
    switch (manga.status) {
      case ReadingStatus.reading:
        return manga.hasNewChapter ? 'New Chapter' : 'Reading';
      case ReadingStatus.onHold:
        return 'On Hold';
      case ReadingStatus.completed:
        return 'Completed';
      case ReadingStatus.planned:
        return 'Planned';
      case ReadingStatus.dropped:
        return 'Dropped';
      case ReadingStatus.caughtUp:
        return 'Caught Up';
    }
  }

  Color get _statusColor {
    if (manga.hasNewChapter) return AppColors.newChapter;
    switch (manga.status) {
      case ReadingStatus.reading:
        return AppColors.reading;
      case ReadingStatus.onHold:
        return AppColors.onHold;
      case ReadingStatus.completed:
        return AppColors.completed;
      case ReadingStatus.planned:
        return AppColors.planned;
      case ReadingStatus.dropped:
        return AppColors.dropped;
      case ReadingStatus.caughtUp:
        return AppColors.caughtUp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox(
          height: 220,
          child: _buildCoverImage(),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final coverUrl = manga.coverUrl;
    return Stack(
      children: [
        if (coverUrl != null)
          Hero(
            tag: 'manga_cover_${manga.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, __, ___) => _coverPlaceholder,
                placeholder: (context, url) => _coverPlaceholder,
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: _coverPlaceholder,
          ),
        // Gradient overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Status indicator pill - top left
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusLabel,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        // Bottom content
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _chapterText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.3,
                      ),
                    ),
                  ),
                  Text(
                    _timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (manga.progress > 0 &&
                  manga.status != ReadingStatus.completed &&
                  manga.status != ReadingStatus.caughtUp &&
                  manga.status != ReadingStatus.planned)
                ProgressBar(progress: manga.progress, color: AppColors.accent),
            ],
          ),
        ),
      ],
    );
  }

  String get _chapterText {
    if (manga.status == ReadingStatus.completed ||
        manga.status == ReadingStatus.caughtUp) {
      return '${manga.currentChapter.toInt()} chapters';
    }
    if (manga.totalChapters != null) {
      return 'Ch. ${manga.currentChapter.toInt()} / ${manga.totalChapters!.toInt()}';
    }
    return 'Chapter ${manga.currentChapter.toInt()}';
  }

  String get _timeAgo => timeAgo(manga.lastUpdate);

  Widget get _coverPlaceholder => const CoverPlaceholder(width: double.infinity, height: 240);
}
