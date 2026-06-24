import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/auth/data/interfaces/auth_service.dart';
import 'package:sumi_app/features/auth/data/services/mangadex_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return MangaDexAuthService();
});
