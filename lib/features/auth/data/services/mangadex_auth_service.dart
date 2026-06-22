import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sumi_app/core/constants/api_config.dart';

class MangaDexAuthService {
  static const _authUrl = ApiConfig.mangadexAuthUrl;
  static const _tokenUrl = ApiConfig.mangadexTokenUrl;
  static const _redirectUri = ApiConfig.mangadexRedirectUri;
  static const _clientId = ApiConfig.mangadexClientId;
  static const _tokenFileName = 'sumi_auth_token.json';

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
        final body = response.body.isNotEmpty ? response.body : 'No response body';
        return 'HTTP ${response.statusCode}: $body';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _sessionToken = data['access_token'] as String?;
      _refreshToken = data['refresh_token'] as String?;
      final expiresIn = data['expires_in'] as int? ?? 3600;
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      await _saveToken();
      return null;
    } catch (e) {
      return 'Exception: $e';
    }
  }

  Future<void> loadToken() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_tokenFileName');
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _sessionToken = data['session'] as String?;
      _refreshToken = data['refresh'] as String?;
      final expiresAtStr = data['expiresAt'] as String?;
      if (expiresAtStr != null) {
        _expiresAt = DateTime.tryParse(expiresAtStr);
      }
    } catch (_) {}
  }

  Future<void> _saveToken() async {
    if (_sessionToken == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_tokenFileName');
      await file.writeAsString(jsonEncode({
        'session': _sessionToken,
        'refresh': _refreshToken,
        'expiresAt': _expiresAt?.toIso8601String(),
      }));
    } catch (_) {}
  }

  Future<void> _clearToken() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_tokenFileName');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> logout() async {
    _sessionToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _lastCodeVerifier = null;
    await _clearToken();
  }

  void dispose() {
    _client.close();
  }
}
