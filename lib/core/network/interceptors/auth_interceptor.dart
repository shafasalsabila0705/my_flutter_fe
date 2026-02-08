import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart';

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;

  AuthInterceptor({required this.localDataSource});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login/register/refresh endpoints to avoid unnecessary storage reads
    if (options.path.contains('/login') ||
        options.path.contains('/register') ||
        options.path.contains('/refresh')) {
      return handler.next(options);
    }

    try {
      final token = await localDataSource.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('AuthInterceptor Error: $e');
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await localDataSource.getRefreshToken();

        // If no refresh token, pass the error (LOGOUT)
        if (refreshToken == null || refreshToken.isEmpty) {
          await localDataSource.clearToken();
          return handler.next(err);
        }

        // Attempt Refresh
        // Use a new Dio instance to avoid interceptor recursion
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        final response = await refreshDio.post(
          '/api/refresh-token',
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final newToken = response.data['token'];
          final newRefreshToken =
              response.data['refresh_token']; // Optional update

          if (newToken != null) {
            // 1. Cache New Tokens
            await localDataSource.cacheToken(newToken);
            if (newRefreshToken != null) {
              await localDataSource.cacheRefreshToken(newRefreshToken);
            }

            // 2. Retry Original Request with New Token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';

            final clonedRequest = await _retry(opts);
            return handler.resolve(clonedRequest);
          }
        }
      } catch (e) {
        // Refresh Failed -> LOGOUT
        debugPrint('Refresh Token Failed: $e');
        await localDataSource.clearToken();
        // Fall through to handler.next(err)
      }
    }

    return handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: requestOptions.baseUrl,
        connectTimeout: requestOptions.connectTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
    );

    // Copy headers
    dio.options.headers = requestOptions.headers;

    // We can't use the original dio because we don't have access to it easily here,
    // unless we pass it in constructor, but creating a fresh one for retry is safer to avoid loops
    // IF we are careful not to add the AuthInterceptor again.
    // However, we just want to execute the request.

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }
}
