import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/manga/presentation/screens/home_screen.dart';

class SumiApp extends ConsumerWidget {
  const SumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sumi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
