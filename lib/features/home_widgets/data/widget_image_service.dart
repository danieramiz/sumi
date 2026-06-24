import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WidgetImageService {
  static final _client = http.Client();

  static Future<String?> downloadCover(String? url, {String? mangaId}) async {
    if (url == null || url.isEmpty) return null;

    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${dir.path}/widget_covers');
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final fileName = '${mangaId ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${coversDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      if (await file.exists()) return file.path;
    } catch (_) {}

    return null;
  }

  static Future<void> cleanup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${dir.path}/widget_covers');
      if (await coversDir.exists()) {
        final files = await coversDir.list().toList();
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        if (files.length > 5) {
          for (final f in files.skip(5)) {
            await f.delete();
          }
        }
      }
    } catch (_) {}
  }
}
