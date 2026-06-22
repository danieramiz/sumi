import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/core/utils/date_utils.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/presentation/widgets/cover_placeholder.dart';
import 'package:sumi_app/features/manga/presentation/widgets/floating_circle_button.dart';
import 'package:sumi_app/features/manga/presentation/widgets/soft_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/status_pill.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/manga/presentation/widgets/progress_bar.dart';
import 'package:sumi_app/features/manga/presentation/screens/chapter_reader_screen.dart';
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
  int _totalChapters = 0;
  bool _chaptersAscending = false;


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
      _chaptersAscending = PreferencesService.instance.chaptersAscending;
      final chapters = await provider.fetchChapters(manga.id, ascending: _chaptersAscending);
      final totalCh = await provider.fetchTotalChapters(manga.id);
      if (mounted) {
        setState(() {
          _manga = manga;
          _chapters = chapters;
          _totalChapters = totalCh;
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    if (_manga == null) return;
    final provider = context.read<MangaProvider>();
    final chapters = await provider.fetchChapters(_manga!.id, ascending: _chaptersAscending);
    if (mounted) {
      setState(() => _chapters = chapters);
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
                child: FloatingCircleButton(
                  size: 40,
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
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
                      child: FloatingCircleButton(
                        size: 40,
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
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
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 140,
        errorWidget: (_, __, ___) => _coverPlaceholder,
        placeholder: (context, url) => _coverPlaceholder,
      );
    }
    return _coverPlaceholder;
  }

  Widget get _coverPlaceholder => const CoverPlaceholder(width: 100, height: 140);

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
        SoftCard(
          child: _buildChaptersRead(context, manga),
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
    final progress = _totalChapters > 0
        ? (manga.currentChapter / _totalChapters).clamp(0.0, 1.0)
        : manga.progress;
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
        ProgressBar(progress: progress),
      ],
    );
  }

  Widget _buildNextChapter(BuildContext context, Manga manga) {
    final latestDate = _chapters.isNotEmpty && _chapters.first.publishDate != null
        ? _chapters.first.publishDate!
        : null;
    final dateStr = latestDate != null
        ? 'Latest: ${latestDate.month}/${latestDate.day}/${latestDate.year}'
        : 'TBD';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricLabel('Latest Chapter'),
        const SizedBox(height: 6),
        Text(
          'Ch. ${(manga.currentChapter).toInt()}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildChaptersRead(BuildContext context, Manga manga) {
    final total = _totalChapters > 0 ? _totalChapters : (manga.currentChapter + 50).toInt();
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
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Favorite toggled (not implemented)')),
            );
          },
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
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit rating (not implemented)')),
            );
          },
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

  Future<void> _toggleChapterSort() async {
    if (_manga == null) return;
    final prefs = PreferencesService.instance;
    prefs.chaptersAscending = !prefs.chaptersAscending;
    await prefs.save();
    final provider = context.read<MangaProvider>();
    final chapters = await provider.fetchChapters(_manga!.id, ascending: prefs.chaptersAscending);
    if (mounted) {
      setState(() {
        _chaptersAscending = prefs.chaptersAscending;
        _chapters = chapters;
      });
    }
  }

  Widget _buildRecentChapters(BuildContext context, Manga manga) {
    final chapters = _chapters;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  'Recent Chapters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleChapterSort,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _chaptersAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _chaptersAscending ? 'Oldest' : 'Newest',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    ? timeAgo(ch.publishDate!)
                    : null;
                return GestureDetector(
                  onLongPress: _manga != null
                      ? () => _showChapterMenu(context, ch, index)
                      : null,
                  child: SoftCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChapterReaderScreen(
                          chapterId: ch.id,
                          onClose: () {
                            if (_manga != null) {
                              context.read<MangaProvider>().markChapterRead(
                                _manga!.id, ch.id,
                              ).then((_) {
                                _loadChapters();
                              });
                            }
                          },
                        ),
                      ),
                    );
                  },
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
                ),
              );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChapterMenu(
      BuildContext context, Chapter chapter, int index) {
    final provider = context.read<MangaProvider>();
    final hasPrevUnread = _chapters
        .sublist(index + 1)
        .any((c) => !c.isRead);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ch. ${chapter.chapterNumber.toInt()}',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                if (hasPrevUnread)
                  _menuAction(
                    ctx,
                    Icons.done_all_rounded,
                    'Mark this and all previous as read',
                    () {
                      Navigator.of(ctx).pop();
                      final ids = <String>[chapter.id];
                      for (int i = index + 1; i < _chapters.length; i++) {
                        if (!_chapters[i].isRead) ids.add(_chapters[i].id);
                      }
                      provider.markChaptersRead(_manga!.id, ids)
                          .then((_) => _loadChapters());
                    },
                  ),
                _menuAction(
                  ctx,
                  Icons.check_rounded,
                  'Mark as read',
                  () {
                    Navigator.of(ctx).pop();
                    provider.markChapterRead(_manga!.id, chapter.id)
                        .then((_) => _loadChapters());
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.secondaryText)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.primaryText),
              ),
            ],
          ),
        ),
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
