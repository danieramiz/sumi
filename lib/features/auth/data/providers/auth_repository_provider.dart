import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/auth/data/providers/auth_service_provider.dart';
import 'package:sumi_app/features/auth/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService: authService);
});
