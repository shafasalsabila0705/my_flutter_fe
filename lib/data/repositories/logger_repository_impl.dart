import 'package:logger/logger.dart';
import '../../features/auth/domain/repositories/logger_repository.dart';

class LoggerRepositoryImpl implements LoggerRepository {
  final Logger _logger;

  LoggerRepositoryImpl() : _logger = Logger();

  @override
  void debug(String message) {
    _logger.d(message);
  }

  @override
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message) {
    _logger.i(message);
  }
}
