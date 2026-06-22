import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/animated_manga_card.dart';
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

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
    return const SizedBox(height: 16);
  }

  Widget _buildMasonryGrid(List<Manga> mangas, BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < mangas.length; i++) {
      final currentManga = mangas[i];
      final card = AnimatedMangaCard(
        manga: currentManga,
        index: i,
        onTap: () => _openDetail(context, currentManga),
        onLongPress: () => _confirmRemove(context, currentManga),
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
        Positioned(
          right: 20,
          bottom: 24,
          child: FloatingCircleButton(
            icon: Icons.menu_rounded,
            onTap: () => _showMenu(context),
          ),
        ),
      ],
    );
  }

  void _confirmRemove(BuildContext context, Manga manga) {
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
                  'Remove from library?',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  manga.title,
                  style: const TextStyle(
                    fontSize: 14, color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: AppColors.dropped,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.read<MangaProvider>().removeFromLibrary(manga.id);
                      },
                      child: const Center(
                        child: Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sumi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),
                if (auth.isAuthenticated)
                  _menuItem(
                    ctx,
                    Icons.logout_rounded,
                    'Logout',
                    () {
                      Navigator.of(ctx).pop();
                      auth.logout();
                      setState(() {
                        _showWelcome = true;
                        _libraryFetched = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
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
              Icon(icon, color: AppColors.primaryText, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
