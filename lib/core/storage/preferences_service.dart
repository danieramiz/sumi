import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum SortOrder { lastUpdated, title }

abstract class PreferencesServiceBase {
  bool get chaptersAscending;
  set chaptersAscending(bool value);
  bool get readerScrollMode;
  set readerScrollMode(bool value);
  bool get notificationsEnabled;
  set notificationsEnabled(bool value);
  String get language;
  set language(String value);
  SortOrder get sortOrder;
  set sortOrder(SortOrder value);
  Set<String> get pinnedMangaIds;
  set pinnedMangaIds(Set<String> value);

  Future<void> load();
  Future<void> save();
}

class PreferencesService implements PreferencesServiceBase {
  static final PreferencesService _instance = PreferencesService._();
  static PreferencesService get instance => _instance;
  PreferencesService._();

  static const _fileName = 'sumi_prefs.json';

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

  @override
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
