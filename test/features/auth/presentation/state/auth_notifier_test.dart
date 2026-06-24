import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumi_app/features/auth/data/interfaces/auth_service.dart';
import 'package:sumi_app/features/auth/data/providers/auth_repository_provider.dart';
import 'package:sumi_app/features/auth/data/repositories/auth_repository.dart';
import 'package:sumi_app/features/auth/presentation/state/auth_notifier.dart';

class MockAuthService implements AuthService {
  bool _authenticated = false;
  String? _token;

  @override
  bool get isAuthenticated => _authenticated;
  @override
  String? get accessToken => _token;

  String? capturedCode;
  bool loadTokenCalled = false;
  bool logoutCalled = false;

  @override
  String buildAuthorizationUrl() => 'https://auth.mangadex.org/login';

  @override
  Future<String?> exchangeCode(String code) async {
    capturedCode = code;
    _authenticated = true;
    _token = code;
    return null;
  }

  @override
  Future<void> loadToken() async {
    loadTokenCalled = true;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _authenticated = false;
    _token = null;
  }

  @override
  void dispose() {}
}

void main() {
  group('AuthNotifier', () {
    test('initial state is uninitialized', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final state = container.read(authProvider);
      expect(state.initialized, false);
      expect(state.isLoading, false);
    });

    test('exchangeCode updates state and authenticates', () async {
      final mockService = MockAuthService();
      final repository = AuthRepository(authService: mockService);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() => container.dispose());

      await container.read(authProvider.notifier).exchangeCode('test_code');
      final state = container.read(authProvider);
      expect(mockService.capturedCode, 'test_code');
      expect(state.isLoading, false);
    });

    test('logout clears authentication', () async {
      final mockService = MockAuthService();
      mockService._token = 'existing';
      mockService._authenticated = true;
      final repository = AuthRepository(authService: mockService);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() => container.dispose());

      await container.read(authProvider.notifier).logout();
      expect(mockService.logoutCalled, true);
    });

    test('buildAuthorizationUrl delegates to repository', () {
      final mockService = MockAuthService();
      final repository = AuthRepository(authService: mockService);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() => container.dispose());

      final url = container.read(authProvider.notifier).buildAuthorizationUrl();
      expect(url, 'https://auth.mangadex.org/login');
    });
  });
}
