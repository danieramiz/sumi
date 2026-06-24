import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumi_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sumi_app/features/home_widgets/presentation/widget_preview_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/chapter_reader_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/home_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/manga_detail_screen.dart';
import 'package:sumi_app/features/manga/presentation/screens/search_screen.dart';
import 'package:sumi_app/features/settings/presentation/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/manga/:id',
        name: 'manga-detail',
        pageBuilder: (_, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: ValueKey(id),
            child: MangaDetailScreen(mangaId: id),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/reader/:chapterId',
        name: 'reader',
        builder: (_, state) {
          final chapterId = state.pathParameters['chapterId']!;
          final mangaId = state.uri.queryParameters['mangaId'];
          final chapterNumStr = state.uri.queryParameters['chapterNum'];
          final chapterNum = chapterNumStr != null ? int.tryParse(chapterNumStr) : null;
          return ChapterReaderScreen(
            chapterId: chapterId,
            mangaId: mangaId,
            chapterNumber: chapterNum,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/widget-preview',
        name: 'widget-preview',
        builder: (_, __) => const WidgetPreviewScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
}
