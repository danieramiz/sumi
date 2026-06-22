import 'package:flutter/foundation.dart';
import 'package:sumi_app/features/auth/data/services/mangadex_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final MangaDexAuthService _authService = MangaDexAuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get accessToken => _authService.accessToken;

  String buildAuthorizationUrl() => _authService.buildAuthorizationUrl();

  Future<void> exchangeCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final errorMsg = await _authService.exchangeCode(code);
    if (errorMsg != null) {
      _error = errorMsg;
    }

    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
