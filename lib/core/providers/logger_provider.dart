import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/core/logger/logger.dart';

final loggerProvider = Provider<Logger>((ref) => const Logger());
