import 'package:sumi_app/features/manga/data/models/chapter_dto.dart';
import 'package:sumi_app/features/manga/data/models/chapter_pages_dto.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';

abstract class MangaService {
  Future<MangaSearchResponse> searchManga({
    String? title,
    int limit = 20,
    int offset = 0,
  });

  Future<MangaDto> getMangaDetails(String id);

  Future<MangaSearchResponse> getFollowedManga(
    String token, {
    int limit = 50,
    int offset = 0,
  });

  Future<List<ChapterDto>> getChapters(
    String mangaId, {
    int limit = 20,
    int offset = 0,
    bool ascending = false,
    String language = 'en',
  });

  Future<ChapterPagesDto> getChapterPages(String chapterId);

  Future<Map<String, dynamic>> getMangaAggregate(
    String mangaId, {
    String? token,
    String language = 'en',
  });

  int parseTotalChapters(Map<String, dynamic> aggregate);

  Future<bool> followManga(String mangaId, String token);
  Future<bool> unfollowManga(String mangaId, String token);

  Future<Set<String>> getReadChapters(String mangaId, String token);

  Future<bool> markChapterRead(String mangaId, String chapterId, String token);

  Future<bool> markChaptersRead(
      String mangaId, List<String> chapterIds, String token);

  Future<bool> setReadingStatus(
      String mangaId, String status, String token);

  String coverUrl(String mangaId, String fileName, {int size = 512});

  void dispose();
}
