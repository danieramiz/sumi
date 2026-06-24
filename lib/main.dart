import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/app/app.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await PreferencesService.instance.load();
  _scheduleWidgetWork();

  runApp(const ProviderScope(child: SumiApp()));
}

void _scheduleWidgetWork() {
  try {
    const MethodChannel('sumi_widget_background').invokeMethod('schedule');
  } catch (_) {
    // Silently fail — WorkManager not critical for app startup
  }
}
