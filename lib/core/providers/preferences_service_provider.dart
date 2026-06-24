import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesServiceBase>((ref) {
  return PreferencesService.instance;
});
