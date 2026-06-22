import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:sumi_app/features/manga/presentation/screens/home_screen.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';

class SumiApp extends StatelessWidget {
  const SumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MangaProvider>(
          create: (_) => MangaProvider(),
          update: (_, auth, manga) => MangaProvider(authProvider: auth),
        ),
      ],
      child: MaterialApp(
        title: 'Sumi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
