import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/manga/presentation/screens/home_screen.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';

class SumiApp extends StatelessWidget {
  const SumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MangaProvider(),
      child: MaterialApp(
        title: 'Sumi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
