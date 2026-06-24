import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumi_app/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  _scheduleWidgetWork();

  runApp(const SumiApp());
}

void _scheduleWidgetWork() {
  try {
    const MethodChannel('sumi_widget_background').invokeMethod('schedule');
  } catch (_) {
    // Silently fail — WorkManager not critical for app startup
  }
}
