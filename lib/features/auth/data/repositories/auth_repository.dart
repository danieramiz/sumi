import 'package:sumi_app/core/logger/logger.dart';
import 'package:sumi_app/features/auth/data/interfaces/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final Logger _log;

  AuthRepository({
    required AuthService authService,
    Logger? logger,
  })  : _authService = authService,
        _log = logger ?? const Logger(tag: 'AuthRepo');

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get accessToken => _authService.accessToken;

  String buildAuthorizationUrl() => _authService.buildAuthorizationUrl();

  Future<String?> exchangeCode(String code) async {
    _log.info('Exchanging auth code');
    final result = await _authService.exchangeCode(code);
    if (result != null) {
      _log.error('Auth code exchange failed: $result');
    } else {
      _log.info('Auth code exchange succeeded');
    }
    return result;
  }

  Future<void> initialize() async {
    _log.debug('Initializing auth - loading saved token');
    await _authService.loadToken();
    _log.info('Auth initialized: ${_authService.isAuthenticated ? "authenticated" : "not authenticated"}');
  }

  Future<void> logout() async {
    _log.info('Logging out');
    await _authService.logout();
  }

  void dispose() => _authService.dispose();
}
