import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumi_app/features/manga/data/models/chapter_dto.dart';
import 'package:sumi_app/features/manga/data/models/manga_dto.dart';

class MangaDexService {
  static const _baseUrl = 'https://api.mangadex.org';
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

  Future<List<ChapterDto>> getChapters(String mangaId, {int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/manga/$mangaId/feed').replace(
      queryParameters: {
        'limit': limit.toString(),
        'translatedLanguage[]': 'en',
        'order[chapter]': 'desc',
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

  Future<Map<String, dynamic>> getMangaAggregate(
    String mangaId, {
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/manga/$mangaId/aggregate').replace(
      queryParameters: {'translatedLanguage[]': 'en'},
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
      'User-Agent': 'SumiApp/1.0',
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
