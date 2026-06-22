import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:sumi_app/features/manga/presentation/screens/home_screen.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';
import 'package:sumi_app/features/manga/presentation/state/manga_provider.dart';

class SumiApp extends StatefulWidget {
  const SumiApp({super.key});

  @override
  State<SumiApp> createState() => _SumiAppState();
}

class _SumiAppState extends State<SumiApp> {
  final _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    PreferencesService.instance.load();
    _authProvider.initialize();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
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
