import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sumi_app/core/constants/api_config.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_service.dart';

Future<bool> runBackgroundUpdate() async {
  final token = await _readToken();
  if (token == null) return false;

  final data = await _fetchWidgetData(token);
  if (data == null) return false;

  await SumiWidgetService().updateAndroidWidgets(data);
  return true;
}

Future<String?> _readToken() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/sumi_auth_token.json');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final token = json['session'] as String?;
    final expiresAtStr = json['expiresAt'] as String?;
    if (token == null || expiresAtStr == null) return null;
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) return null;
    return token;
  } catch (_) {
    return null;
  }
}

Future<SumiWidgetData?> _fetchWidgetData(String token) async {
  try {
    final client = http.Client();
    try {
      final url = '${ApiConfig.mangadexBaseUrl}/user/follows/manga'
          '?limit=20&includes[]=cover_art';
      final response = await client.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final mangaList = body['data'] as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> mangas = [];
      for (final m in mangaList) {
        final attrs = m['attributes'] as Map<String, dynamic>? ?? {};
        final rels = m['relationships'] as List<dynamic>? ?? [];
        String? coverFileName;
        for (final r in rels) {
          if (r['type'] == 'cover_art') {
            final rAttrs = r['attributes'] as Map<String, dynamic>?;
            coverFileName = rAttrs?['fileName'] as String?;
          }
        }

        final mangaId = m['id'] as String? ?? '';
        final titleMap = attrs['title'] as Map<String, dynamic>? ?? {};
        final title = titleMap['en'] as String? ??
            titleMap.values.firstOrNull as String? ??
            'Unknown';

        mangas.add({
          'id': mangaId,
          'title': title,
          'coverFileName': coverFileName,
          'lastChapter': attrs['lastChapter'],
          'updatedAt': attrs['updatedAt'],
        });
      }

      if (mangas.isEmpty) return null;

      final first = mangas.first;
      final coverUrl = first['coverFileName'] != null
          ? 'https://uploads.mangadex.org/covers/${first['id']}/${first['coverFileName']}.256.jpg'
          : null;

      final updates = mangas.take(3).map((m) {
        final updatedAt = m['updatedAt'] as String?;
        final timeAgo = updatedAt != null ? _timeAgo(DateTime.tryParse(updatedAt)) : 'recent';
        final lastCh = m['lastChapter'];
        final chLabel = lastCh != null ? 'Ch. ${lastCh.toString()}' : '';
        return ChapterWidgetUpdate(
          mangaTitle: m['title'] as String,
          chapterLabel: chLabel,
          timeAgo: timeAgo,
        );
      }).toList();

      return SumiWidgetData(
        newChapterCount: mangas.length,
        continueReading: MangaWidgetItem(
          title: first['title'] as String,
          chapterLabel: 'Ch. ${first['lastChapter']?.toString() ?? '?'}',
          coverUrl: coverUrl ?? '',
          progress: 0.5,
        ),
        updates: updates,
      );
    } finally {
      client.close();
    }
  } catch (_) {
    return null;
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return 'recent';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).round()}w ago';
}
