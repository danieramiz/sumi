import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/auth/data/providers/auth_repository_provider.dart';
import 'package:sumi_app/features/auth/data/repositories/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final bool initialized;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.initialized = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? initialized,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    ref.onDispose(() => _repository.dispose());
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    await _repository.initialize();
    state = state.copyWith(initialized: true, isAuthenticated: _repository.isAuthenticated);
  }

  String? get accessToken => _repository.accessToken;

  String buildAuthorizationUrl() => _repository.buildAuthorizationUrl();

  Future<void> exchangeCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    final errorMsg = await _repository.exchangeCode(code);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: errorMsg == null && _repository.isAuthenticated,
      error: errorMsg,
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(initialized: true, isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
