import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/manga/data/interfaces/manga_service.dart';
import 'package:sumi_app/features/manga/data/services/mangadex_service.dart';

final mangaServiceProvider = Provider<MangaService>((ref) {
  return MangaDexService();
});
