import 'package:dio/dio.dart';

class ThrottleInterceptor extends Interceptor {
  final Duration throttleDuration;
  final Map<String, DateTime> _lastRequestTime = {};

  ThrottleInterceptor({this.throttleDuration = const Duration(seconds: 2)});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Generate unique key untuk request
    final key = _generateRequestKey(options);

    // Check throttle
    if (_lastRequestTime.containsKey(key)) {
      final lastTime = _lastRequestTime[key]!;
      final elapsed = DateTime.now().difference(lastTime);

      if (elapsed < throttleDuration) {
        final waitTime = throttleDuration - elapsed;

        // Log throttle warning
        print(
          'Throttling request to ${options.path}. '
          'Waiting ${waitTime.inMilliseconds}ms',
        );

        // Tunggu sampai throttle time habis
        await Future.delayed(waitTime);
      }
    }

    // Mark request time
    _lastRequestTime[key] = DateTime.now();

    // Lanjutkan request
    handler.next(options);
  }

  /// Generate unique key untuk request
  /// Bisa dicustom sesuai kebutuhan
  String _generateRequestKey(RequestOptions options) {
    // Key berdasarkan method + path + body (untuk POST/PUT)
    if (options.method == 'GET' || options.data == null) {
      return '${options.method}_${options.path}';
    }

    // Untuk request dengan body, hash body untuk key
    final bodyHash = options.data.hashCode;
    return '${options.method}_${options.path}_$bodyHash';
  }

  /// Clear throttle history (opsional, untuk testing)
  void clear() {
    _lastRequestTime.clear();
  }
}
