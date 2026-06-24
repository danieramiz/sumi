import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_notifier.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/widgets/animated_manga_card.dart';
import 'package:sumi_app/features/manga/presentation/widgets/floating_circle_button.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showWelcome = true;
  bool _libraryFetched = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mangaState = ref.watch(mangaProvider);
    final mangaNotifier = ref.read(mangaProvider.notifier);

    if (!authState.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showWelcome && !authState.isAuthenticated) {
      return _buildWelcomeScreen(context);
    }

    if (authState.isAuthenticated && !_libraryFetched) {
      _libraryFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mangaNotifier.fetchLibrary();
      });
    }

    final mangas = mangaState.followedManga;

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
                SliverToBoxAdapter(child: _buildHeader(context)),
                if (mangaState.isLibraryLoading)
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
                  onTap: () => context.push('/search'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    const _logoPink = Color(0xFFFF4F6D);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/icons/sumi_logo_light.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Sumi',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your beautiful manga companion.\nFollow, track, and discover.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.push('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _logoPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Sign in with MangaDex'),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _showWelcome = false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.6),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Browse sample data'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
    final authState = ref.read(authProvider);
    final mangaNotifier = ref.read(mangaProvider.notifier);
    if (authState.isAuthenticated) {
      await mangaNotifier.fetchLibrary();
    }
  }

  void _openDetail(BuildContext context, Manga manga) {
    context.push('/manga/${manga.id}');
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          bottom: 24,
          child: FloatingCircleButton(
            icon: Icons.search_rounded,
            onTap: () => context.push('/search'),
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
    final authState = ref.read(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final mangaNotifier = ref.read(mangaProvider.notifier);
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
                    await context.push('/settings');
                    mangaNotifier.refreshSort();
                  },
                ),
                _menuItem(
                  ctx,
                  Icons.widgets_rounded,
                  'Widget Preview',
                  () {
                    Navigator.of(ctx).pop();
                    context.push('/widget-preview');
                  },
                ),
                const SizedBox(height: 8),
                if (authState.isAuthenticated)
                  _menuItem(
                    ctx,
                    Icons.logout_rounded,
                    'Logout',
                    () {
                      Navigator.of(ctx).pop();
                      authNotifier.logout();
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
    final mangaNotifier = ref.read(mangaProvider.notifier);
    final pinned = mangaNotifier.isPinned(manga.id);
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
                      mangaNotifier.togglePin(manga.id);
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
