import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/manga_masonry_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/floating_circle_button.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';
import 'package:sumi_app/features/manga/presentation/screens/manga_detail_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWelcome = true;
  bool _libraryFetched = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mangaProvider = context.watch<MangaProvider>();

    if (_showWelcome && !auth.isAuthenticated) {
      return _buildWelcomeScreen(context);
    }

    if (auth.isAuthenticated && !_libraryFetched) {
      _libraryFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mangaProvider.fetchLibrary();
      });
    }

    final mangas = mangaProvider.mangaList;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, auth)),
                if (mangaProvider.isLibraryLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (mangas.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Your library is empty.\nTap search to find manga.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverToBoxAdapter(
                      child: _buildMasonryGrid(mangas, context),
                    ),
                  ),
              ],
            ),
            if (mangas.isNotEmpty) _buildFloatingButtons(context),
            if (mangas.isEmpty)
              Positioned(
                right: 20,
                bottom: 24,
                child: FloatingCircleButton(
                  icon: Icons.search_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SearchScreen()),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                'Sumi',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 48,
                      color: AppColors.accent,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your beautiful manga companion.\nFollow, track, and discover.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Text(
                        'Sign in with MangaDex',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        setState(() => _showWelcome = false);
                      },
                      child: const Center(
                        child: Text(
                          'Browse sample data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Text(
            'Library',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          if (auth.isAuthenticated)
            GestureDetector(
              onTap: () {
                auth.logout();
                setState(() {
                  _showWelcome = true;
                  _libraryFetched = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
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
        items.add(
            Padding(padding: const EdgeInsets.only(top: 60), child: card));
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
