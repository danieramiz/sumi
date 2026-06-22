import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/manga_masonry_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/floating_circle_button.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';
import 'package:sumi_app/features/manga/presentation/screens/manga_detail_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mangas = context.watch<MangaProvider>().mangaList;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverToBoxAdapter(
                    child: _buildMasonryGrid(mangas, context),
                  ),
                ),
              ],
            ),
            _buildFloatingButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Text(
            'Library',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          FloatingCircleButton(
            icon: Icons.more_horiz_rounded,
            size: 40,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryGrid(List<Manga> mangas, BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < mangas.length; i++) {
      final card = MangaMasonryCard(
        manga: mangas[i],
        onTap: () => _openDetail(context, mangas[i]),
      );
      if (i == 1) {
        items.add(Padding(padding: const EdgeInsets.only(top: 60), child: card));
      } else {
        items.add(card);
      }
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  void _openDetail(BuildContext context, Manga manga) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MangaDetailScreen(mangaId: manga.id),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          bottom: 24,
          child: FloatingCircleButton(
            icon: Icons.search_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ),
        const Positioned(
          right: 20,
          bottom: 24,
          child: FloatingCircleButton(icon: Icons.tune_rounded),
        ),
      ],
    );
  }
}
