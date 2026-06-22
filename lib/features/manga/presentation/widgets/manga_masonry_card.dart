import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/soft_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/status_pill.dart';
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
    final isCompact = manga.progress == 1.0 || manga.status == ReadingStatus.planned;

    return GestureDetector(
      onLongPress: onLongPress,
      child: SoftCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
              ),
              child: SizedBox(
                height: 120,
                child: _buildCoverImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _chapterText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusPill(label: _statusLabel, customColor: _statusColor),
                      const Spacer(),
                      Text(
                        _timeAgo,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  if (!isCompact && manga.progress > 0) ...[
                    const SizedBox(height: 10),
                    ProgressBar(
                      progress: manga.progress,
                      color: _statusColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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

  String get _timeAgo {
    final diff = DateTime.now().difference(manga.lastUpdate);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Widget _buildCoverImage() {
    final coverUrl = manga.coverUrl;
    if (coverUrl != null) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        errorBuilder: (_, __, ___) => _coverPlaceholder,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _coverPlaceholder;
        },
      );
    }
    return _coverPlaceholder;
  }

  Widget get _coverPlaceholder {
    return Container(
      color: AppColors.accent.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Container(
        width: 80,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.image),
        ),
        child: const Center(
          child: Icon(Icons.auto_stories, color: AppColors.accent, size: 32),
        ),
      ),
    );
  }
}
