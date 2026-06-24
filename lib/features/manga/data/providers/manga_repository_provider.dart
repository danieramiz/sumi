import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/core/providers/logger_provider.dart';
import 'package:sumi_app/core/providers/preferences_service_provider.dart';
import 'package:sumi_app/features/home_widgets/data/providers/widget_service_provider.dart';
import 'package:sumi_app/features/manga/data/providers/manga_service_provider.dart';
import 'package:sumi_app/features/manga/data/repositories/manga_repository.dart';

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  final mangaService = ref.watch(mangaServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  final widgetService = ref.watch(widgetServiceProvider);
  final log = ref.watch(loggerProvider);
  return MangaRepository(
    api: mangaService,
    prefs: prefs,
    widgetService: widgetService,
    logger: log,
  );
});
