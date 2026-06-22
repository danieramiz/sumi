import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._();
  static PreferencesService get instance => _instance;
  PreferencesService._();

  static const _fileName = 'sumi_prefs.json';

  bool chaptersAscending = false;
  bool readerScrollMode = false;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      chaptersAscending = data['chaptersAscending'] as bool? ?? false;
      readerScrollMode = data['readerScrollMode'] as bool? ?? false;
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonEncode({
        'chaptersAscending': chaptersAscending,
        'readerScrollMode': readerScrollMode,
      }));
    } catch (_) {}
  }
}
