enum FailureType { network, api, auth, cache, unknown }

class Failure {
  final FailureType type;
  final String message;
  final String? details;
  final Object? originalError;

  const Failure({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
  });

  String get userFacingMessage {
    switch (type) {
      case FailureType.network:
        return 'Could not connect to MangaDex. Check your internet connection.';
      case FailureType.api:
        return 'MangaDex returned an error. Please try again.';
      case FailureType.auth:
        return message;
      case FailureType.cache:
        return 'Could not load cached data.';
      case FailureType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}

Failure networkFailure([Object? error]) => Failure(
  type: FailureType.network,
  message: 'Network request failed',
  originalError: error,
);

Failure apiFailure(String details, [Object? error]) => Failure(
  type: FailureType.api,
  message: 'API error: $details',
  details: details,
  originalError: error,
);

Failure authFailure(String message, [Object? error]) => Failure(
  type: FailureType.auth,
  message: message,
  originalError: error,
);

Failure unknownFailure([Object? error]) => Failure(
  type: FailureType.unknown,
  message: 'Unexpected error',
  originalError: error,
);
