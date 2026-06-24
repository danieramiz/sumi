import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/home_widgets/data/interfaces/widget_service.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/manga/data/interfaces/manga_service.dart';
import 'package:sumi_app/features/manga/data/models/chapter_dto.dart';
import 'package:sumi_app/features/manga/data/models/chapter_pages_dto.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';
import 'package:sumi_app/features/manga/data/repositories/manga_repository.dart';
import 'package:sumi_app/features/manga/domain/entities/chapter.dart';
import 'package:sumi_app/features/manga/domain/entities/manga.dart';

class MockMangaService implements MangaService {
  List<MangaDto> mockSearchResults = [];
  MangaDto? mockDetails;
  List<MangaDto> mockFollowed = [];
  List<ChapterDto> mockChapters = [];
  ChapterPagesDto? mockPages;
  Map<String, dynamic> mockAggregate = {};
  Set<String> mockReadIds = {};
  bool followResult = true;
  bool unfollowResult = true;
  bool markReadResult = true;
  bool markChaptersReadResult = true;
  bool statusResult = true;

  String? lastFollowMangaId;
  String? lastUnfollowMangaId;
  String? lastMarkChapterId;
  List<String>? lastMarkChapterIds;
  String? lastStatus;
  String? lastToken;

  @override
  Future<MangaSearchResponse> searchManga({String? title, int limit = 20, int offset = 0}) async {
    return MangaSearchResponse(data: mockSearchResults, total: mockSearchResults.length);
  }

  @override
  Future<MangaDto> getMangaDetails(String id) async {
    if (mockDetails == null) throw Exception('Not found');
    return mockDetails!;
  }

  @override
  Future<MangaSearchResponse> getFollowedManga(String token, {int limit = 50, int offset = 0}) async {
    lastToken = token;
    return MangaSearchResponse(data: mockFollowed, total: mockFollowed.length);
  }

  @override
  Future<List<ChapterDto>> getChapters(String mangaId, {int limit = 20, int offset = 0, bool ascending = false, String language = 'en'}) async {
    return mockChapters;
  }

  @override
  Future<ChapterPagesDto> getChapterPages(String chapterId) async {
    return mockPages ?? ChapterPagesDto(baseUrl: '', hash: '', pages: [], dataSaverPages: []);
  }

  @override
  Future<Map<String, dynamic>> getMangaAggregate(String mangaId, {String? token, String language = 'en'}) async {
    if (mangaId == 'nonexistent') throw Exception('Not found');
    return mockAggregate;
  }

  @override
  int parseTotalChapters(Map<String, dynamic> aggregate) => 5;

  @override
  Future<bool> followManga(String mangaId, String token) async {
    lastFollowMangaId = mangaId;
    return followResult;
  }

  @override
  Future<bool> unfollowManga(String mangaId, String token) async {
    lastUnfollowMangaId = mangaId;
    return unfollowResult;
  }

  @override
  Future<Set<String>> getReadChapters(String mangaId, String token) async {
    return mockReadIds;
  }

  @override
  Future<bool> markChapterRead(String mangaId, String chapterId, String token) async {
    lastMarkChapterId = chapterId;
    return markReadResult;
  }

  @override
  Future<bool> markChaptersRead(String mangaId, List<String> chapterIds, String token) async {
    lastMarkChapterIds = chapterIds;
    return markChaptersReadResult;
  }

  @override
  Future<bool> setReadingStatus(String mangaId, String status, String token) async {
    lastStatus = status;
    lastToken = token;
    return statusResult;
  }

  @override
  String coverUrl(String mangaId, String fileName, {int size = 512}) {
    return 'https://uploads.mangadex.org/covers/$mangaId/$fileName.$size.jpg';
  }

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
  SumiWidgetData? lastData;

  @override
  Future<void> updateAndroidWidgets(SumiWidgetData data) async {
    lastData = data;
  }
}

MangaDto _createMangaDto({
  String id = 'manga_1',
  String title = 'Test Manga',
  String? coverFileName,
}) {
  return MangaDto(
    id: id,
    title: {'en': title},
    description: {'en': 'A test manga'},
    status: 'ongoing',
    lastChapter: 10,
    genres: ['Action', 'Adventure'],
    coverFileName: coverFileName,
    author: 'Test Author',
    updatedAt: DateTime(2024, 1, 1),
  );
}

  ChapterDto _createChapterDto({
  String id = 'ch_1',
  double chapter = 1.0,
  String title = 'Chapter 1',
}) {
  return ChapterDto(
    id: id,
    chapter: chapter.toString(),
    title: title,
    publishDate: '2024-01-01T00:00:00.000Z',
  );
}

void main() {
  late MockMangaService mockApi;
  late MockPreferencesService mockPrefs;
  late MockWidgetService mockWidget;
  late MangaRepository repository;

  setUp(() {
    mockApi = MockMangaService();
    mockPrefs = MockPreferencesService();
    mockWidget = MockWidgetService();
    repository = MangaRepository(api: mockApi, prefs: mockPrefs, widgetService: mockWidget);
  });

  group('MangaRepository', () {
    group('sortLibrary', () {
      test('sorts by lastUpdated by default', () {
        final manga = [
          Manga(id: '2', title: 'Z Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 6, 1)),
          Manga(id: '1', title: 'A Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 1, 1)),
        ];
        final sorted = repository.sortLibrary(manga);
        expect(sorted.first.id, '2');
      });

      test('sorts by title when sortOrder is title', () {
        mockPrefs.sortOrder = SortOrder.title;
        final manga = [
          Manga(id: '2', title: 'Z Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 1, 1)),
          Manga(id: '1', title: 'A Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 6, 1)),
        ];
        final sorted = repository.sortLibrary(manga);
        expect(sorted.first.id, '1');
      });

      test('pinned manga appear first', () {
        mockPrefs.pinnedMangaIds = {'pinned_id'};
        final manga = [
          Manga(id: 'pinned_id', title: 'B Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 1, 1)),
          Manga(id: 'normal_id', title: 'A Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 0, progress: 0, lastUpdate: DateTime(2024, 6, 1)),
        ];
        final sorted = repository.sortLibrary(manga);
        expect(sorted.first.id, 'pinned_id');
      });
    });

    group('searchManga', () {
      test('returns list of Manga from service results', () async {
        mockApi.mockSearchResults = [_createMangaDto(id: 's1', title: 'Found Manga')];
        final results = await repository.searchManga('found');
        expect(results.length, 1);
        expect(results.first.title, 'Found Manga');
      });

      test('returns empty list when no results', () async {
        mockApi.mockSearchResults = [];
        final results = await repository.searchManga('nothing');
        expect(results, isEmpty);
      });
    });

    group('fetchFollowedManga', () {
      test('returns followed manga with token', () async {
        mockApi.mockFollowed = [_createMangaDto(id: 'f1', title: 'Followed')];
        final results = await repository.fetchFollowedManga('token123');
        expect(results.length, 1);
        expect(mockApi.lastToken, 'token123');
      });
    });

    group('fetchMangaDetails', () {
      test('returns null on error', () async {
        mockApi.mockDetails = null;
        final result = await repository.fetchMangaDetails('unknown');
        expect(result, isNull);
      });
    });

    group('togglePin', () {
      test('adds pin when not pinned', () async {
        expect(mockPrefs.pinnedMangaIds, isEmpty);
        await repository.togglePin('manga_1');
        expect(mockPrefs.pinnedMangaIds, contains('manga_1'));
      });

      test('removes pin when already pinned', () async {
        mockPrefs.pinnedMangaIds = {'manga_1'};
        await repository.togglePin('manga_1');
        expect(mockPrefs.pinnedMangaIds, isNot(contains('manga_1')));
      });
    });

    group('isPinned', () {
      test('returns true when manga is pinned', () {
        mockPrefs.pinnedMangaIds = {'manga_1'};
        expect(repository.isPinned('manga_1'), true);
      });

      test('returns false when manga is not pinned', () {
        expect(repository.isPinned('manga_1'), false);
      });
    });

    group('followManga', () {
      test('calls service followManga with correct id', () async {
        await repository.followManga('manga_1', 'token');
        expect(mockApi.lastFollowMangaId, 'manga_1');
      });
    });

    group('unfollowManga', () {
      test('calls service unfollowManga with correct id', () async {
        await repository.unfollowManga('manga_1', 'token');
        expect(mockApi.lastUnfollowMangaId, 'manga_1');
      });
    });

    group('setReadingStatus', () {
      test('calls service with correct status', () async {
        await repository.setReadingStatus('manga_1', 'reading', 'token');
        expect(mockApi.lastStatus, 'reading');
        expect(mockApi.lastToken, 'token');
      });
    });

    group('fetchChapters', () {
      test('returns list of Chapter entities', () async {
        mockApi.mockChapters = [_createChapterDto(id: 'ch_1', chapter: 1.0)];
        final chapters = await repository.fetchChapters('manga_1');
        expect(chapters.length, 1);
        expect(chapters.first.id, 'ch_1');
        expect(chapters.first.chapterNumber, 1.0);
      });

      test('returns empty list on error', () async {
        mockApi.mockChapters = [];
        final chapters = await repository.fetchChapters('nonexistent');
        expect(chapters, isEmpty);
      });
    });

    group('fetchChaptersWithReadStatus', () {
      test('marks chapters as read based on readIds', () async {
        mockApi.mockChapters = [
          _createChapterDto(id: 'ch_1', chapter: 1.0),
          _createChapterDto(id: 'ch_2', chapter: 2.0),
        ];
        mockApi.mockReadIds = {'ch_1'};
        final chapters = await repository.fetchChaptersWithReadStatus('manga_1', token: 'token');
        expect(chapters[0].isRead, true);
        expect(chapters[1].isRead, false);
      });

      test('all chapters unread when no token', () async {
        mockApi.mockChapters = [_createChapterDto(id: 'ch_1')];
        final chapters = await repository.fetchChaptersWithReadStatus('manga_1');
        expect(chapters.first.isRead, false);
      });
    });

    group('fetchTotalChapters', () {
      test('returns parsed total from aggregate', () async {
        final total = await repository.fetchTotalChapters('manga_1');
        expect(total, 5);
      });

      test('returns 0 on error', () async {
        final total = await repository.fetchTotalChapters('nonexistent');
        expect(total, 0);
      });
    });

    group('markChapterRead', () {
      test('calls service with chapter id', () async {
        await repository.markChapterRead('manga_1', 'ch_1', 'token');
        expect(mockApi.lastMarkChapterId, 'ch_1');
      });
    });

    group('markChaptersRead', () {
      test('calls service with chapter ids', () async {
        await repository.markChaptersRead('manga_1', ['ch_1', 'ch_2'], 'token');
        expect(mockApi.lastMarkChapterIds, ['ch_1', 'ch_2']);
      });
    });

    group('getMockLibrary', () {
      test('returns non-empty mock list', () {
        final mock = repository.getMockLibrary();
        expect(mock, isNotEmpty);
        expect(mock.first.title, isNotEmpty);
      });
    });

    group('updateWidgets', () {
      test('does nothing when list is empty', () {
        repository.updateWidgets([]);
        expect(mockWidget.lastData, isNull);
      });

      test('updates widget with correct data', () {
        final manga = [
          Manga(id: '1', title: 'Active Manga', author: '', description: '', genres: [], status: ReadingStatus.reading, currentChapter: 5, progress: 0.5, lastUpdate: DateTime(2024, 6, 1)),
        ];
        repository.updateWidgets(manga);
        expect(mockWidget.lastData, isNotNull);
        expect(mockWidget.lastData!.continueReading!.title, 'Active Manga');
      });
    });
  });
}
