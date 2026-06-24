abstract class AuthService {
  bool get isAuthenticated;
  String? get accessToken;

  String buildAuthorizationUrl();
  Future<String?> exchangeCode(String code);
  Future<void> loadToken();
  Future<void> logout();
  void dispose();
}
