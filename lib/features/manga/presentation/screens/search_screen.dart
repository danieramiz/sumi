import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_notifier.dart';
import 'package:sumi_app/features/manga/presentation/screens/manga_detail_screen.dart';
import 'package:sumi_app/features/manga/presentation/widgets/cover_placeholder.dart';
import 'package:sumi_app/core/routes/hero_detail_route.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mangaState = ref.watch(mangaProvider);
    final mangaNotifier = ref.read(mangaProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primaryText,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primaryText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search manga...',
                          hintStyle: TextStyle(color: AppColors.secondaryText),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _hasSearched = true;
                            mangaNotifier.searchManga(value.trim());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (mangaState.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mangaState.error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      mangaState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.dropped),
                    ),
                  ),
                ),
              )
            else if (!_hasSearched)
              const Expanded(
                child: Center(
                  child: Text(
                    'Search for manga to add to your library',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              )
            else if (mangaState.searchResults.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: mangaState.searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final manga = mangaState.searchResults[index];
                      return _SearchResultCard(
                        manga: manga,
                        inLibrary: mangaNotifier.isInLibrary(manga.id),
                        onTap: () {
                          Navigator.of(context).push(
                            HeroDetailRoute(
                              page: MangaDetailScreen(mangaId: manga.id),
                            ),
                          );
                        },
                        onAdd: () => mangaNotifier.addToLibrary(manga),
                        onRemove: () => mangaNotifier.removeFromLibrary(manga.id),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Manga manga;
  final bool inLibrary;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _SearchResultCard({
    required this.manga,
    required this.inLibrary,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.image),
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: _buildCover(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (manga.genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        manga.genres.take(3).join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (manga.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        manga.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  inLibrary ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  color: inLibrary ? AppColors.reading : AppColors.accent,
                ),
                onPressed: inLibrary ? onRemove : onAdd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    final coverUrl = manga.coverUrl;
    if (coverUrl != null) {
      return _cachedImage(coverUrl);
    }
    return const CoverPlaceholder(width: 56, height: 80);
  }

  Widget _cachedImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const CoverPlaceholder(width: 56, height: 80),
      placeholder: (context, url) => const CoverPlaceholder(width: 56, height: 80),
    );
  }
}
