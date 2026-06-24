import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/auth/data/interfaces/auth_service.dart';
import 'package:sumi_app/features/auth/data/repositories/auth_repository.dart';

class MockAuthService implements AuthService {
  bool _authenticated = false;
  String? _token;

  @override
  bool get isAuthenticated => _authenticated;
  @override
  String? get accessToken => _token;

  String? lastAuthorizationUrl;
  String? lastExchangeCode;
  bool loadTokenCalled = false;
  bool logoutCalled = false;
  bool disposeCalled = false;

  @override
  String buildAuthorizationUrl() {
    lastAuthorizationUrl = 'https://auth.mangadex.org/authorize';
    return lastAuthorizationUrl!;
  }

  @override
  Future<String?> exchangeCode(String code) async {
    lastExchangeCode = code;
    _token = 'mock_token_$code';
    _authenticated = true;
    return null;
  }

  @override
  Future<void> loadToken() async {
    loadTokenCalled = true;
    _authenticated = true;
    _token = 'loaded_token';
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _authenticated = false;
    _token = null;
  }

  @override
  void dispose() {
    disposeCalled = true;
  }
}

void main() {
  late MockAuthService mockService;
  late AuthRepository repository;

  setUp(() {
    mockService = MockAuthService();
    repository = AuthRepository(authService: mockService);
  });

  group('AuthRepository', () {
    test('isAuthenticated delegates to service', () {
      expect(repository.isAuthenticated, false);
      mockService._authenticated = true;
      expect(repository.isAuthenticated, true);
    });

    test('accessToken delegates to service', () {
      expect(repository.accessToken, null);
      mockService._token = 'test_token';
      expect(repository.accessToken, 'test_token');
    });

    test('buildAuthorizationUrl delegates to service', () {
      final url = repository.buildAuthorizationUrl();
      expect(url, 'https://auth.mangadex.org/authorize');
      expect(mockService.lastAuthorizationUrl, isNotNull);
    });

    test('exchangeCode delegates to service and returns null on success', () async {
      final error = await repository.exchangeCode('test_code');
      expect(error, isNull);
      expect(mockService.lastExchangeCode, 'test_code');
    });

    test('initialize calls loadToken', () async {
      await repository.initialize();
      expect(mockService.loadTokenCalled, true);
    });

    test('logout delegates to service', () async {
      await repository.logout();
      expect(mockService.logoutCalled, true);
    });

    test('dispose delegates to service', () {
      repository.dispose();
      expect(mockService.disposeCalled, true);
    });
  });
}
