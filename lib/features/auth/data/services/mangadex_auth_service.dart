import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class MangaDexAuthService {
  static const _authUrl =
      'https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/auth';
  static const _tokenUrl =
      'https://auth.mangadex.org/realms/mangadex/protocol/openid-connect/token';
  static const _redirectUri = 'https://mangadex.org/auth/login';
  static const _clientId = 'mangadex-frontend-stable';

  final http.Client _client;

  String? _sessionToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _lastCodeVerifier;

  MangaDexAuthService({http.Client? client}) : _client = client ?? http.Client();

  bool get isAuthenticated =>
      _sessionToken != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  String? get accessToken => _sessionToken;

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String buildAuthorizationUrl() {
    _lastCodeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_lastCodeVerifier!);
    return Uri.parse(_authUrl).replace(queryParameters: {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    }).toString();
  }

  Future<String?> exchangeCode(String code) async {
    if (_lastCodeVerifier == null) {
      return 'No code verifier available';
    }

    try {
      final response = await _client.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code': code,
          'redirect_uri': _redirectUri,
          'code_verifier': _lastCodeVerifier!,
        },
      );

      if (response.statusCode != 200) {
        final body =
            response.body.isNotEmpty ? response.body : 'No response body';
        return 'HTTP ${response.statusCode}: $body';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _sessionToken = data['access_token'] as String?;
      _refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 3600;
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      return null;
    } catch (e) {
      return 'Exception: $e';
    }
  }

  void logout() {
    _sessionToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _lastCodeVerifier = null;
  }

  void dispose() {
    _client.close();
  }
}
