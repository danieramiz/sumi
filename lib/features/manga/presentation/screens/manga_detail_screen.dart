import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/core/utils/date_utils.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/presentation/screens/chapter_reader_screen.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';

class MangaDetailScreen extends StatefulWidget {
  final String mangaId;
  const MangaDetailScreen({super.key, required this.mangaId});
  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> with SingleTickerProviderStateMixin {
  Manga? _manga;
  bool _loading = true;
  List<Chapter> _chapters = [];
  final _seenNums = <int>{};
  int _totalChapters = 0;
  int _markTarget = 0;
  bool _chaptersAscending = false;
  bool _isLoadingMore = false;
  bool _hasMoreChapters = true;
  final _chapterScrollController = ScrollController();
  final _detailScrollController = ScrollController();
  late final AnimationController _staggerController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _chapterScrollController.addListener(_onChapterScroll);
    _detailScrollController.addListener(() {
      setState(() => _scrollOffset = _detailScrollController.offset);
    });
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final provider = context.read<MangaProvider>();
    final cached = provider.getMangaById(widget.mangaId);
    if (cached != null) {
      _chaptersAscending = PreferencesService.instance.chaptersAscending;
      _manga = cached;
    }
    _loadManga();
  }

  @override
  void dispose() {
    _chapterScrollController.dispose();
    _detailScrollController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _onChapterScroll() {
    if (_chapterScrollController.position.pixels >=
            _chapterScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreChapters) {
      _loadMoreChapters();
    }
  }

  Future<void> _loadManga() async {
    final provider = context.read<MangaProvider>();
    var manga = provider.getMangaById(widget.mangaId);
    if (manga == null) {
      manga = await provider.fetchMangaDetails(widget.mangaId);
    }
    if (manga != null) {
      _chaptersAscending = PreferencesService.instance.chaptersAscending;
      final chapters = await provider.fetchChapters(manga.id,
          ascending: _chaptersAscending, limit: 20);
      final totalCh = await provider.fetchTotalChapters(manga.id);
      _seenNums.clear();
      for (final c in chapters) {
        _seenNums.add(c.chapterNumber.round());
      }
      if (mounted) setState(() {
        _manga = manga;
        _chapters = chapters;
        _totalChapters = totalCh;
        _markTarget = _readCountFromChapters(chapters, manga!.currentChapter.toInt());
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _staggerController.forward();
      });
    } else if (mounted) setState(() => _loading = false);
  }

  int _readCountFromChapters(List<Chapter> chapters, int fallback) {
    final seen = <int>{};
    var max = 0;
    for (final c in chapters) {
      final n = c.chapterNumber.round();
      if (c.isRead && n > 0 && seen.add(n) && n > max) {
        max = n;
      }
    }
    return max > 0 ? max : fallback;
  }

  String _fmtChapterNum(double n) {
    final r = n.roundToDouble();
    return n == r ? r.toInt().toString() : n.toString();
  }

  Widget _staggerSlide(int index, Widget child) {
    final double start = index * 0.08;
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _staggerController,
        builder: (context, _) {
          final progress = _staggerController.value;
          final t = ((progress - start) / 0.5).clamp(0.0, 1.0);
          final eased = Curves.easeOut.transform(t);
          return Opacity(
            opacity: eased,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - eased)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _popWithAnimation() async {
    await _staggerController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _loadMoreChapters() async {
    if (_isLoadingMore || _manga == null) return;
    _isLoadingMore = true;
    if (mounted) setState(() {});
    final provider = context.read<MangaProvider>();
    final more = await provider.fetchChapters(_manga!.id,
        ascending: _chaptersAscending, offset: _chapters.length, limit: 20);
    if (mounted) {
      final deduped = more.where((c) => _seenNums.add(c.chapterNumber.round())).toList();
      setState(() {
        if (deduped.isEmpty) {
          _hasMoreChapters = false;
        } else {
          _chapters.addAll(deduped);
        }
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    if (_manga == null) return;
    final provider = context.read<MangaProvider>();
    _hasMoreChapters = true;
    final chapters = await provider.fetchChapters(_manga!.id,
        ascending: _chaptersAscending, limit: 20);
    _seenNums.clear();
    for (final c in chapters) {
      _seenNums.add(c.chapterNumber.round());
    }
    if (mounted) setState(() {
      _chapters = chapters;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final manga = _manga;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: CustomScrollView(
        controller: _detailScrollController,
        slivers: [
          _buildHero(manga),
          if (manga == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(color: Color(0xFF8B7EF6))
                    : const Text('Manga not found', style: TextStyle(color: Colors.white54)),
              ),
            )
          else ...[
            _staggerSlide(0, _primaryStatsPanel(manga)),
            _staggerSlide(1, _readingJourneyPanel(manga)),
            _staggerSlide(2, _chapterTimelinePanel(manga)),
            _staggerSlide(3, _aboutPanel(manga)),
            _staggerSlide(4, _infoPanel(manga)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(Manga? manga) {
    final screenHeight = MediaQuery.of(context).size.height;
    final coverUrl = manga?.coverUrl;
    return SliverAppBar(
      expandedHeight: screenHeight * 0.40,
      pinned: false,
      floating: false,
      backgroundColor: const Color(0xFF0D1117),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(0, _scrollOffset * 0.3),
              child: Hero(
                tag: 'manga_cover_${widget.mangaId}',
                child: Material(
                  type: MaterialType.transparency,
                  child: coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _heroPlaceholder,
                          placeholder: (_, __) => _heroPlaceholder,
                        )
                      : _heroPlaceholder,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1117).withValues(alpha: 0.3),
                    Colors.transparent,
                    const Color(0xFF0D1117).withValues(alpha: 0.85),
                    const Color(0xFF0D1117),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12, top: MediaQuery.of(context).padding.top + 4,
              child: _circleBtn(Icons.arrow_back_rounded, _popWithAnimation),
            ),
            Positioned(
              right: 12, top: MediaQuery.of(context).padding.top + 4,
              child: _circleBtn(Icons.more_horiz_rounded, _showMenu),
            ),
            if (manga != null) Positioned(
              left: 20, right: 20, bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(manga.title, style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                    height: 1.15,
                  )),
                  const SizedBox(height: 6),
                  Text(manga.author.isNotEmpty ? manga.author : 'Unknown',
                      style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.65))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: manga.genres.map((g) => _genrePill(g)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryStatsPanel(Manga manga) {
    final latestCh = _chapters.isNotEmpty ? _chapters.first : null;
    final latestNum = latestCh?.chapterNumber ?? manga.currentChapter;
    final total = _totalChapters > 0 ? _totalChapters : null;
    final currentRead = _markTarget > 0 ? _markTarget : manga.currentChapter.toInt();
    final pct = total != null && total > 0
        ? ((currentRead / total) * 100).round()
        : (manga.progress * 100).round();
    final statusLabel = _statusLabel(manga);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(child: _statCard('Progress', '${pct}%',
              '$currentRead / ${total ?? '?'} chapters', Icons.pie_chart_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Latest', 'Ch. ${latestNum.toInt()}',
              latestCh?.publishDate != null ? timeAgo(latestCh!.publishDate!) : 'No data',
              Icons.auto_stories_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('Status', statusLabel,
              manga.readingSince != null ? 'Started ${_formatDate(manga.readingSince!)}' : '—',
              Icons.circle_outlined)),
        ],
      ),
    );
  }

  Widget _readingJourneyPanel(Manga manga) {
    final effectiveRead = _markTarget > 0 ? _markTarget : manga.currentChapter.toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _journeyCard(manga, effectiveRead),
    );
  }

  Widget _chapterTimelinePanel(Manga manga) {
    final chapters = _chapters;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Chapters', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleChapterSort,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _chaptersAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 14, color: const Color(0xFF8B7EF6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _chaptersAscending ? 'Oldest' : 'Newest',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8B7EF6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          if (chapters.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(
              child: Text('No chapters available', style: TextStyle(color: Colors.white38)),
            ))
          else
            SizedBox(
              height: (chapters.length * 52.0).clamp(0, 800),
              child: ListView.separated(
                controller: _chapterScrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: chapters.length + (_hasMoreChapters ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  if (index >= chapters.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B7EF6))),
                    );
                  }
                  return _chapterTile(chapters[index]);
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _aboutPanel(Manga manga) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Text(
                manga.description.isNotEmpty ? manga.description : 'No description available.',
                style: TextStyle(
                  fontSize: 15, height: 1.6, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
    );
  }

  Widget _infoPanel(Manga manga) {
    final altTitles = <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Information', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                _infoRow('Author', manga.author.isNotEmpty ? manga.author : 'Unknown'),
                _infoDivider(),
                _infoRow('Status', manga.status.toString().split('.').last),
                _infoDivider(),
                _infoRow('Chapters', _totalChapters > 0 ? '$_totalChapters' : '—'),
                if (altTitles.isNotEmpty) ...[
                  _infoDivider(),
                  _infoRow('Also Known As', altTitles.join(', ')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chapterTile(Chapter ch) {
    final dateStr = ch.publishDate != null ? timeAgo(ch.publishDate!) : null;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChapterReaderScreen(
              chapterId: ch.id,
              onClose: () {
                if (_manga != null) {
                  context.read<MangaProvider>().markChapterRead(_manga!.id, ch.id)
                      .then((_) {
                    _markTarget = ch.chapterNumber.toInt();
                    _loadChapters();
                  });
                }
              },
            ),
          ),
        );
      },
      onLongPress: _manga != null ? () => _showChapterMenu(ch) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ch.isRead ? Colors.white24 : const Color(0xFF8B7EF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ch.chapterNumber > 0
                    ? 'Chapter ${_fmtChapterNum(ch.chapterNumber)}'
                    : 'Chapter ?',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (dateStr != null)
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8B7EF6)),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _journeyCard(Manga manga, int readCount) {
    final chapNum = readCount > 0 ? readCount : manga.currentChapter.toInt();
    final maxChNum = _chapters.fold<double>(0, (max, c) => c.chapterNumber > max ? c.chapterNumber : max);
    final total = maxChNum > 0 ? maxChNum.round() : _totalChapters;
    final behind = total > 0 ? (total - chapNum).clamp(0, 9999) : 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF8B7EF6)),
              const SizedBox(width: 8),
              const Text('Reading Journey', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _journeyMetric('$chapNum', 'read'),
              const SizedBox(width: 32),
              _journeyMetric('$total', 'total'),
              const SizedBox(width: 32),
              _journeyMetric('$behind', 'behind'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _JourneyChartPainter(chapterCount: chapNum.clamp(0, 500).toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _genrePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
    );
  }

  void _showMenu() {
    if (_manga == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                _darkMenuItem(ctx, Icons.remove_circle_outline_rounded, 'Remove from library', Colors.redAccent, () {
                  Navigator.of(ctx).pop();
                  context.read<MangaProvider>().removeFromLibrary(_manga!.id);
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChapterMenu(Chapter ch) {
    final provider = context.read<MangaProvider>();
    final idx = _chapters.indexOf(ch);
    final hasPrevUnread = _chapters.sublist(idx + 1).any((c) => !c.isRead);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Text('Chapter ${ch.chapterNumber.toInt()}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 20),
                if (hasPrevUnread)
                  _darkMenuItem(ctx, Icons.done_all_rounded, 'Mark this and previous as read', const Color(0xFF8B7EF6), () {
                    Navigator.of(ctx).pop();
                    final ids = <String>[ch.id];
                    for (int i = idx + 1; i < _chapters.length; i++) {
                      if (!_chapters[i].isRead) ids.add(_chapters[i].id);
                    }
                    provider.markChaptersRead(_manga!.id, ids).then((_) {
                      _markTarget = ch.chapterNumber.toInt();
                      _loadChapters();
                    });
                  }),
                _darkMenuItem(ctx, Icons.check_rounded, 'Mark as read', const Color(0xFF8B7EF6), () {
                  Navigator.of(ctx).pop();
                  provider.markChapterRead(_manga!.id, ch.id).then((_) {
                    _markTarget = ch.chapterNumber.toInt();
                    _loadChapters();
                  });
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleChapterSort() async {
    if (_manga == null) return;
    final prefs = PreferencesService.instance;
    prefs.chaptersAscending = !prefs.chaptersAscending;
    await prefs.save();
    final provider = context.read<MangaProvider>();
    final chapters = await provider.fetchChapters(_manga!.id, ascending: prefs.chaptersAscending);
    if (mounted) setState(() {
      _chaptersAscending = prefs.chaptersAscending;
      _chapters = chapters;
    });
  }

  Widget _darkMenuItem(BuildContext context, IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40, height: 40,
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _infoDivider() => Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);

  Widget get _heroPlaceholder => Container(color: const Color(0xFF1E1E2E));

  String _formatDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _statusLabel(Manga manga) {
    switch (manga.status) {
      case ReadingStatus.reading: return 'Reading';
      case ReadingStatus.onHold: return 'On Hold';
      case ReadingStatus.completed: return 'Completed';
      case ReadingStatus.planned: return 'Planned';
      case ReadingStatus.dropped: return 'Dropped';
      case ReadingStatus.caughtUp: return 'Caught Up';
    }
  }
}

class _JourneyChartPainter extends CustomPainter {
  final double chapterCount;
  _JourneyChartPainter({required this.chapterCount});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B7EF6).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = const Color(0xFF8B7EF6).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = [0.1, 0.3, 0.2, 0.5, 0.4, 0.6, 0.55, 0.7, 0.65, 0.8];
    path.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
