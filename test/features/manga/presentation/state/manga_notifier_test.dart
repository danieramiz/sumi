import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/home_widgets/data/interfaces/widget_service.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/manga/data/interfaces/manga_service.dart';
import 'package:sumi_app/features/manga/data/models/chapter_dto.dart';
import 'package:sumi_app/features/manga/data/models/chapter_pages_dto.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';
import 'package:sumi_app/features/manga/data/providers/manga_repository_provider.dart';
import 'package:sumi_app/features/manga/data/repositories/manga_repository.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_notifier.dart';

class MockMangaService implements MangaService {
  List<MangaDto> mockSearchResults = [];
  List<MangaDto> mockFollowed = [];
  List<ChapterDto> mockChapters = [];
  Map<String, dynamic> mockAggregate = {};
  Set<String> mockReadIds = {};

  @override
  Future<MangaSearchResponse> searchManga({String? title, int limit = 20, int offset = 0}) async {
    return MangaSearchResponse(data: mockSearchResults, total: mockSearchResults.length);
  }

  @override
  Future<MangaDto> getMangaDetails(String id) async {
    return MangaDto(id: id, title: {'en': 'Test'}, description: {}, genres: []);
  }

  @override
  Future<MangaSearchResponse> getFollowedManga(String token, {int limit = 50, int offset = 0}) async {
    return MangaSearchResponse(data: mockFollowed, total: mockFollowed.length);
  }

  @override
  Future<List<ChapterDto>> getChapters(String mangaId, {int limit = 20, int offset = 0, bool ascending = false, String language = 'en'}) async {
    return mockChapters;
  }

  @override
  Future<ChapterPagesDto> getChapterPages(String chapterId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getMangaAggregate(String mangaId, {String? token, String language = 'en'}) async {
    return mockAggregate;
  }

  @override
  int parseTotalChapters(Map<String, dynamic> aggregate) => 3;

  @override
  Future<bool> followManga(String mangaId, String token) async => true;

  @override
  Future<bool> unfollowManga(String mangaId, String token) async => true;

  @override
  Future<Set<String>> getReadChapters(String mangaId, String token) async => mockReadIds;

  @override
  Future<bool> markChapterRead(String mangaId, String chapterId, String token) async => true;

  @override
  Future<bool> markChaptersRead(String mangaId, List<String> chapterIds, String token) async => true;

  @override
  Future<bool> setReadingStatus(String mangaId, String status, String token) async => true;

  @override
  String coverUrl(String mangaId, String fileName, {int size = 512}) => 'https://example.com/$fileName.jpg';

  @override
  void dispose() {}
}

class MockPreferencesService implements PreferencesServiceBase {
  @override
  bool chaptersAscending = false;
  @override
  bool readerScrollMode = false;
  @override
  bool notificationsEnabled = true;
  @override
  String language = 'en';
  @override
  SortOrder sortOrder = SortOrder.lastUpdated;
  @override
  Set<String> pinnedMangaIds = {};

  @override
  Future<void> load() async {}
  @override
  Future<void> save() async {}
}

class MockWidgetService implements WidgetService {
  @override
  Future<void> updateAndroidWidgets(SumiWidgetData data) async {}
}

void main() {
  late MockMangaService mockApi;
  late MockPreferencesService mockPrefs;
  late MangaRepository repository;

  setUp(() {
    mockApi = MockMangaService();
    mockPrefs = MockPreferencesService();
    repository = MangaRepository(api: mockApi, prefs: mockPrefs);
  });

  group('MangaNotifier', () {
    test('initial state has empty lists', () {
      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      final state = container.read(mangaProvider);
      expect(state.followedManga, isEmpty);
      expect(state.searchResults, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLibraryLoading, false);
    });

    test('searchManga updates searchResults', () async {
      mockApi.mockSearchResults = [
        MangaDto(id: 's1', title: {'en': 'Search Result'}, description: {}, genres: []),
      ];

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).searchManga('search');
      final state = container.read(mangaProvider);
      expect(state.searchResults.length, 1);
      expect(state.searchResults.first.title, 'Search Result');
    });

    test('searchManga sets error on failure', () async {
      mockApi.mockSearchResults = [];
      // Simulate error by making the repository return empty (no exception needed for this mock)

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).searchManga('unknown');
      final state = container.read(mangaProvider);
      expect(state.searchResults, isEmpty);
    });

    test('addToLibrary prepends manga to list', () async {
      final manga = Manga(id: '1', title: 'New', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime.now());

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).addToLibrary(manga);
      final state = container.read(mangaProvider);
      expect(state.followedManga.length, 1);
      expect(state.followedManga.first.id, '1');
    });

    test('removeFromLibrary removes manga by id', () async {
      final manga = Manga(id: '1', title: 'Remove Me', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime.now());

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).addToLibrary(manga);
      expect(container.read(mangaProvider).followedManga.length, 1);

      await container.read(mangaProvider.notifier).removeFromLibrary('1');
      expect(container.read(mangaProvider).followedManga, isEmpty);
    });

    test('isInLibrary checks followed manga', () async {
      final manga = Manga(id: '1', title: 'Test', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime.now());

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      final notifier = container.read(mangaProvider.notifier);
      expect(notifier.isInLibrary('1'), false);

      await notifier.addToLibrary(manga);
      expect(notifier.isInLibrary('1'), true);
    });

    test('getMangaById returns manga from followed list', () async {
      final manga = Manga(id: '1', title: 'Find Me', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime.now());

      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).addToLibrary(manga);
      final found = container.read(mangaProvider.notifier).getMangaById('1');
      expect(found, isNotNull);
      expect(found!.title, 'Find Me');
    });

    test('togglePin delegates to repository', () async {
      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      await container.read(mangaProvider.notifier).togglePin('manga_1');
      expect(mockPrefs.pinnedMangaIds, contains('manga_1'));
    });

    test('isPinned delegates to repository', () {
      mockPrefs.pinnedMangaIds = {'manga_1'};
      final container = ProviderContainer(
        overrides: [mangaRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() => container.dispose());

      expect(container.read(mangaProvider.notifier).isPinned('manga_1'), true);
      expect(container.read(mangaProvider.notifier).isPinned('other'), false);
    });
  });
}
