import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumi_app/core/providers/preferences_service_provider.dart';
import 'package:sumi_app/features/manga/data/interfaces/manga_service.dart';
import 'package:sumi_app/features/manga/data/providers/manga_service_provider.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_notifier.dart';

enum ReadingMode { paged, scroll }

class ChapterReaderScreen extends ConsumerStatefulWidget {
  final String chapterId;
  final String? mangaId;
  final int? chapterNumber;

  const ChapterReaderScreen({
    super.key,
    required this.chapterId,
    this.mangaId,
    this.chapterNumber,
  });

  @override
  ConsumerState<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends ConsumerState<ChapterReaderScreen> {
  late final MangaService _api;
  List<String> _pageUrls = [];
  bool _loading = true;
  String? _error;
  ReadingMode _mode = ReadingMode.paged;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _api = ref.read(mangaServiceProvider);
    _mode = ref.read(preferencesServiceProvider).readerScrollMode
        ? ReadingMode.scroll
        : ReadingMode.paged;
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final data = await _api.getChapterPages(widget.chapterId);
      if (mounted) {
        setState(() {
          _pageUrls = data.qualityUrls();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _markReadAndPop() {
    final mangaId = widget.mangaId;
    if (mangaId != null) {
      ref.read(mangaProvider.notifier).markChapterRead(mangaId, widget.chapterId);
    }
    context.pop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, style: const TextStyle(color: Colors.white)),
              ),
            )
          else if (_mode == ReadingMode.paged)
            _buildPagedView()
          else
            _buildScrollView(),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildPagedView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pageUrls.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: _pageUrls[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      child: Column(
        children: _pageUrls.map((url) {
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            width: double.infinity,
            placeholder: (context, url) => const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white24),
              ),
            ),
            errorWidget: (_, __, ___) => const SizedBox(
              height: 300,
              child: Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 48),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: 12,
          right: 12,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _markReadAndPop();
                  },
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            const Spacer(),
            if (!_loading) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${_pageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final prefs = ref.read(preferencesServiceProvider);
                      prefs.readerScrollMode = _mode != ReadingMode.scroll;
                      prefs.save();
                      setState(() {
                        _mode = _mode == ReadingMode.paged
                            ? ReadingMode.scroll
                            : ReadingMode.paged;
                      });
                    },
                    child: Icon(
                      _mode == ReadingMode.paged
                          ? Icons.view_stream_rounded
                          : Icons.view_carousel_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
