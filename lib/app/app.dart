import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/app/router.dart';
import 'package:sumi_app/app/theme.dart';

class SumiApp extends ConsumerWidget {
  const SumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sumi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
