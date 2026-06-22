import 'package:flutter/material.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/manga/data/services/mangadex_service.dart';

enum ReadingMode { paged, scroll }

class ChapterReaderScreen extends StatefulWidget {
  final String chapterId;
  final VoidCallback? onClose;

  const ChapterReaderScreen({super.key, required this.chapterId, this.onClose});

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  final MangaDexService _api = MangaDexService();
  List<String> _pageUrls = [];
  bool _loading = true;
  String? _error;
  ReadingMode _mode = ReadingMode.paged;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _mode = PreferencesService.instance.readerScrollMode
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

  @override
  void dispose() {
    _pageController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
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
            child: Image.network(
              _pageUrls[index],
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white24),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
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
          return Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white24),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const SizedBox(
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
                    widget.onClose?.call();
                    Navigator.of(context).pop();
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
                      final prefs = PreferencesService.instance;
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
