import 'package:dio/dio.dart';

class DioClient {
  static Dio getDio() {
    return Dio(
      BaseOptions(
        baseUrl: 'http://172.23.14.140:3000',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
  }
}
