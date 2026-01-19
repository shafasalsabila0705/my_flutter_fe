class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, {this.originalError});

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  ServerException(super.message, {super.originalError});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.originalError});
}

class CacheException extends AppException {
  CacheException(super.message, {super.originalError});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.originalError});
}
