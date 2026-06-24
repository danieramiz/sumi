import 'package:sumi_app/features/auth/data/interfaces/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({required AuthService authService})
      : _authService = authService;

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get accessToken => _authService.accessToken;

  String buildAuthorizationUrl() => _authService.buildAuthorizationUrl();

  Future<String?> exchangeCode(String code) =>
      _authService.exchangeCode(code);

  Future<void> initialize() => _authService.loadToken();

  Future<void> logout() => _authService.logout();

  void dispose() => _authService.dispose();
}
