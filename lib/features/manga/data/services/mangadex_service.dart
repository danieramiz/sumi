import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumi_app/core/constants/api_config.dart';
import 'package:sumi_app/features/manga/data/models/chapter_dto.dart';
import 'package:sumi_app/features/manga/data/models/chapter_pages_dto.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';

class MangaDexService {
  static const _baseUrl = ApiConfig.mangadexBaseUrl;
  final http.Client _client;

  MangaDexService({http.Client? client}) : _client = client ?? http.Client();

  Future<MangaSearchResponse> searchManga({
    String? title,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'contentRating[]': ['safe', 'suggestive'],
      'order[followedCount]': 'desc',
      'includes[]': 'cover_art',
    };
    if (title != null && title.isNotEmpty) {
      params['title'] = title;
    }

    final uri = Uri.parse('$_baseUrl/manga').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    return MangaSearchResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<MangaDto> getMangaDetails(String id) async {
    final uri = Uri.parse('$_baseUrl/manga/$id')
        .replace(queryParameters: {'includes[]': 'cover_art'});
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return MangaDto.fromJson(data);
  }

  Future<MangaSearchResponse> getFollowedManga(
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/user/follows/manga').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'includes[]': 'cover_art',
      },
    );
    final response = await _client.get(
      uri,
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    return MangaSearchResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ChapterDto>> getChapters(String mangaId,
      {int limit = 20, int offset = 0, bool ascending = false, String language = 'en'}) async {
    final uri = Uri.parse('$_baseUrl/manga/$mangaId/feed').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'translatedLanguage[]': language,
        'order[chapter]': ascending ? 'asc' : 'desc',
      },
    );
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    return ChapterFeedResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    ).data;
  }

  Future<ChapterPagesDto> getChapterPages(String chapterId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/at-home/server/$chapterId'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    return ChapterPagesDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> getMangaAggregate(
    String mangaId, {
    String? token,
    String language = 'en',
  }) async {
    final uri = Uri.parse('$_baseUrl/manga/$mangaId/aggregate').replace(
      queryParameters: {'translatedLanguage[]': language},
    );
    final response = await _client.get(
      uri,
      headers: _headers(token: token),
    );
    if (response.statusCode != 200) {
      throw Exception('MangaDex API error: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  int parseTotalChapters(Map<String, dynamic> aggregate) {
    final volumes = aggregate['volumes'] as Map<String, dynamic>? ?? {};
    final chapters = <String>{};
    for (final vol in volumes.values) {
      final volMap = vol as Map<String, dynamic>;
      final chs = volMap['chapters'] as Map<String, dynamic>? ?? {};
      chapters.addAll(chs.keys);
    }
    return chapters.length;
  }

  Future<bool> followManga(String mangaId, String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/manga/$mangaId/follow'),
      headers: _headers(token: token),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> unfollowManga(String mangaId, String token) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/manga/$mangaId/follow'),
      headers: _headers(token: token),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<Set<String>> getReadChapters(String mangaId, String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/manga/$mangaId/read'),
      headers: _headers(token: token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toSet();
    }
    return {};
  }

  Future<bool> markChapterRead(String mangaId, String chapterId, String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/manga/$mangaId/read'),
      headers: _headers(token: token),
      body: jsonEncode({'chapterIdsRead': [chapterId]}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> markChaptersRead(
      String mangaId, List<String> chapterIds, String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/manga/$mangaId/read'),
      headers: _headers(token: token),
      body: jsonEncode({'chapterIdsRead': chapterIds}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> setReadingStatus(
      String mangaId, String status, String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/manga/$mangaId/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  String coverUrl(String mangaId, String fileName, {int size = 512}) {
    return 'https://uploads.mangadex.org/covers/$mangaId/$fileName.$size.jpg';
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': ApiConfig.userAgent,
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void dispose() {
    _client.close();
  }
}
