import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/presentation/widgets/soft_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/status_pill.dart';
import 'package:sumi_app/features/manga/presentation/widgets/progress_bar.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';

class MangaDetailScreen extends StatefulWidget {
  final String mangaId;

  const MangaDetailScreen({super.key, required this.mangaId});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  Manga? _manga;
  bool _loading = true;
  List<Chapter> _chapters = [];


  @override
  void initState() {
    super.initState();
    _loadManga();
  }

  Future<void> _loadManga() async {
    final provider = context.read<MangaProvider>();
    var manga = provider.getMangaById(widget.mangaId);
    if (manga == null) {
      manga = await provider.fetchMangaDetails(widget.mangaId);
    }
    if (manga != null) {
      final chapters = await provider.fetchChapters(manga.id);
      if (mounted) {
        setState(() {
          _manga = manga;
          _chapters = chapters;
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text('Loading...', style: TextStyle(color: AppColors.secondaryText)),
              ],
            ),
          ),
        ),
      );
    }

    final manga = _manga;
    if (manga == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Manga not found')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _roundIconButton(
                  Icons.arrow_back_rounded,
                  () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline_rounded,
                              color: AppColors.dropped, size: 20),
                          SizedBox(width: 10),
                          Text('Remove from library',
                              style: TextStyle(color: AppColors.dropped)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'remove' && _manga != null) {
                      context.read<MangaProvider>().removeFromLibrary(_manga!.id);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IgnorePointer(
                      child: _roundIconButton(Icons.more_horiz_rounded, () {}),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(child: _buildHeader(context, manga)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: _buildDashboard(context, manga)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: _buildRecentChapters(context, manga),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        boxShadow: AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: AppColors.primaryText, size: 22),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Manga manga) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.image),
            child: SizedBox(
              width: 100,
              height: 140,
              child: _buildCoverImage(manga),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  manga.author,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: manga.genres
                      .map((g) => StatusPill(label: g))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Manga manga) {
    final coverUrl = manga.coverUrl;
    if (coverUrl != null) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 140,
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
      child: const Center(
        child: Icon(Icons.auto_stories, color: AppColors.accent, size: 36),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Manga manga) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SoftCard(
                child: _buildCurrentlyReading(context, manga),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SoftCard(
                child: _buildNextChapter(context, manga),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SoftCard(
                child: _buildReadingProgress(context, manga),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SoftCard(
                child: _buildChaptersRead(context, manga),
              ),
            ),
          ],
        ),
        if (manga.currentArc != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: _buildCurrentArc(context, manga),
          ),
        ],
        if (manga.topCharacter != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: _buildTopCharacter(context, manga),
          ),
        ],
        if (manga.rating != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: _buildMyRating(context, manga),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentlyReading(BuildContext context, Manga manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Currently Reading'),
        const SizedBox(height: 6),
        Text(
          manga.currentChapter.toInt().toString(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.accent,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          manga.lastUpdate.toString().substring(0, 10),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ProgressBar(progress: manga.progress),
      ],
    );
  }

  Widget _buildNextChapter(BuildContext context, Manga manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Next Chapter'),
        const SizedBox(height: 6),
        Text(
          'Ch. ${(manga.currentChapter + 1).toInt()}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          manga.nextChapterInfo ?? 'TBD',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: i < 3
                      ? AppColors.accent
                      : AppColors.progressBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReadingProgress(BuildContext context, Manga manga) {
    final sinceStr = manga.readingSince != null
        ? '${manga.readingSince!.year}-${manga.readingSince!.month.toString().padLeft(2, '0')}'
        : 'Unknown';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Reading Since'),
        const SizedBox(height: 6),
        Text(
          sinceStr,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '~${manga.totalReadingTime?.inHours ?? 0}h total',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 24,
          child: CustomPaint(
            size: const Size(double.infinity, 24),
            painter: _MiniChartPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersRead(BuildContext context, Manga manga) {
    final total = manga.totalChapters ?? (manga.currentChapter + 50);
    final pct = ((manga.currentChapter / total) * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Chapters Read'),
        const SizedBox(height: 6),
        Text(
          '${manga.currentChapter.toInt()}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.accent,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '/ ${total.toInt()} total',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: pct >= 80 ? AppColors.reading : AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentArc(BuildContext context, Manga manga) {
    final arc = manga.currentArc!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Current Arc'),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.image),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.accentLight,
                child: const Center(
                  child: Icon(Icons.map_outlined,
                      color: AppColors.accent, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arc.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ch. ${arc.startChapter.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(
                    progress: arc.progress,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopCharacter(BuildContext context, Manga manga) {
    final char = manga.topCharacter!;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.image),
          child: Container(
            width: 56,
            height: 56,
            color: AppColors.accentLight,
            child: const Center(
              child: Icon(Icons.person_outline,
                  color: AppColors.accent, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricLabel('Favorite Character'),
              const SizedBox(height: 4),
              Text(
                char.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            char.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: char.isFavorite ? Colors.red : AppColors.secondaryText,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMyRating(BuildContext context, Manga manga) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metricLabel('My Rating'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  manga.rating!.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  return Icon(
                    i < manga.rating!.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.accent,
                    size: 20,
                  );
                }),
              ],
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Edit',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChapters(BuildContext context, Manga manga) {
    final chapters = _chapters;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Recent Chapters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final ch = chapters[index];
                final dateStr = ch.publishDate != null
                    ? '${ch.publishDate!.month}/${ch.publishDate!.day}'
                    : null;
                return SoftCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ch.chapterNumber > 0
                            ? 'Ch. ${ch.chapterNumber.toInt()}'
                            : 'Ch. ?',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      if (dateStr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ch.isRead
                              ? AppColors.secondaryText
                              : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryText,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final points = [0.3, 0.4, 0.35, 0.6, 0.55, 0.7, 0.65, 0.75];

    path.moveTo(0, size.height * (1 - points[0]));
    for (int i = 1; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
