import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum SortOrder { lastUpdated, title }

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._();
  static PreferencesService get instance => _instance;
  PreferencesService._();

  static const _fileName = 'sumi_prefs.json';

  bool chaptersAscending = false;
  bool readerScrollMode = false;
  bool notificationsEnabled = true;
  String language = 'en';
  SortOrder sortOrder = SortOrder.lastUpdated;
  Set<String> pinnedMangaIds = {};

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      chaptersAscending = data['chaptersAscending'] as bool? ?? false;
      readerScrollMode = data['readerScrollMode'] as bool? ?? false;
      notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
      language = data['language'] as String? ?? 'en';
      sortOrder =
          SortOrder.values.firstWhere((s) => s.name == data['sortOrder'],
              orElse: () => SortOrder.lastUpdated);
      final pinnedList = data['pinnedMangaIds'] as List<dynamic>? ?? [];
      pinnedMangaIds = pinnedList.map((e) => e.toString()).toSet();
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsString(jsonEncode({
        'chaptersAscending': chaptersAscending,
        'readerScrollMode': readerScrollMode,
        'notificationsEnabled': notificationsEnabled,
        'language': language,
        'sortOrder': sortOrder.name,
        'pinnedMangaIds': pinnedMangaIds.toList(),
      }));
    } catch (_) {}
  }
}
