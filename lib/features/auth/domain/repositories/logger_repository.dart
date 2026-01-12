/// LoggerRepository Interface
/// Abstract away the logging library to keep Domain pure.
abstract class LoggerRepository {
  void debug(String message);
  void error(String message, {dynamic error, StackTrace? stackTrace});
  void info(String message);
}
