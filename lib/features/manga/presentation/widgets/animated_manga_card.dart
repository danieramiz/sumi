import 'package:flutter/material.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/manga_masonry_card.dart';

class AnimatedMangaCard extends StatefulWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final int index;

  const AnimatedMangaCard({
    super.key,
    required this.manga,
    this.onTap,
    required this.index,
  });

  @override
  State<AnimatedMangaCard> createState() => _AnimatedMangaCardState();
}

class _AnimatedMangaCardState extends State<AnimatedMangaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    final delay = Duration(milliseconds: widget.index * 75);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: MangaMasonryCard(
          manga: widget.manga,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
