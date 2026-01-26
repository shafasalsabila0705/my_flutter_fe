import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/throttle_interceptor.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

class ApiClient {
  late final Dio _dio;
  final AuthLocalDataSource authLocalDataSource;

  ApiClient({
    required String baseUrl,
    required this.authLocalDataSource,
    Duration throttleDuration = const Duration(seconds: 2),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      // Auth Interceptor
      AuthInterceptor(localDataSource: authLocalDataSource),

      // Throttle interceptor (tambahkan pertama/setelah auth)
      ThrottleInterceptor(throttleDuration: throttleDuration),

      // ... existing interceptors

      // Log interceptor (debug)
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _dio.delete(path, data: data);
  }
}
