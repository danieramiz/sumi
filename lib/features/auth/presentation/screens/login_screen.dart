import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _webLoading = true;
  bool _codeProcessed = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() => _webLoading = true);
            _checkUrlForCode(url, auth);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _webLoading = false);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(auth.buildAuthorizationUrl()));
  }

  void _checkUrlForCode(String url, AuthProvider auth) {
    if (_codeProcessed) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.host.contains('mangadex.org') && uri.path == '/auth/login') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        _codeProcessed = true;
        auth.exchangeCode(code).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.primaryText,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in to MangaDex',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (auth.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dropped.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  auth.error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.dropped),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_webLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
