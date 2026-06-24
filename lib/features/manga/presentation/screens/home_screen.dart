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
import 'package:sumi_app/core/routes/hero_detail_route.dart';
import 'package:sumi_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sumi_app/features/home_widgets/presentation/widget_preview_screen.dart';

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

    final mangas = mangaProvider.followedManga;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _onRefresh(context),
              displacement: 40,
              color: AppColors.accent,
              child: CustomScrollView(
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
      final card = GestureDetector(
        onLongPress: () => _showCardMenu(context, currentManga),
        child: AnimatedMangaCard(
          manga: currentManga,
          index: i,
          onTap: () => _openDetail(context, currentManga),
        ),
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

  Future<void> _onRefresh(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final mangaProvider = context.read<MangaProvider>();
    if (auth.isAuthenticated) {
      await mangaProvider.fetchLibrary();
    }
  }

  void _openDetail(BuildContext context, Manga manga) {
    Navigator.of(context).push(
      HeroDetailRoute(
        page: MangaDetailScreen(mangaId: manga.id),
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
                _menuItem(
                  ctx,
                  Icons.settings_rounded,
                  'Settings',
                  () async {
                    Navigator.of(ctx).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                    context.read<MangaProvider>().refreshSort();
                  },
                ),
                _menuItem(
                  ctx,
                  Icons.widgets_rounded,
                  'Widget Preview',
                  () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const WidgetPreviewScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
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

  void _showCardMenu(BuildContext context, Manga manga) {
    final provider = context.read<MangaProvider>();
    final pinned = provider.isPinned(manga.id);
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
                  manga.title,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      provider.togglePin(manga.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                            color: AppColors.accent, size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            pinned ? 'Unpin from top' : 'Pin to top',
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.primaryText),
                          ),
                        ],
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
}
