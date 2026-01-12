import 'package:dio/dio.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String nip, String password);
  Future<String> register({
    required String nip,
    required String password,
    required String name,
    String? email,
    String? phone,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String nip, String password) async {
    try {
      final response = await dio.post(
        '/api/login',
        data: {'nip': nip, 'password': password},
      );

      if (response.statusCode == 200) {
        // Response format: {"message": "Login Berhasil!", "token": "..."}
        // Since we don't get user details, we create a temporary UserModel.
        // In a real app, we would use the token to fetch the user profile.
        final token = response.data['token'] as String? ?? '';

        return UserModel(
          id: token.isNotEmpty ? token : 'generated-id',
          nip: nip,
          name:
              'Pegawai (Kota Padang)', // Placeholder since API does not return name yet
          email: null,
          phone: null,
        );
      } else {
        throw ServerException(response.statusMessage ?? 'Server Error');
      }
    } on DioException catch (e) {
      // DEBUG LOGGING
      print('LOGIN DIO ERROR: ${e.type} - ${e.message}');
      print('LOGIN DIO RESPONSE: ${e.response?.data}');

      throw ServerException(
        e.response?.data['message'] ?? e.message ?? AppStrings.networkError,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> register({
    required String nip,
    required String password,
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await dio.post(
        '/api/register',
        data: {
          'nip': nip,
          'password': password,
          'name': name,
          'email': email,
          'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Registrasi Berhasil';
      } else {
        throw ServerException(response.statusMessage ?? 'Server Error');
      }
    } on DioException catch (e) {
      // DEBUG LOGGING
      print('DIO ERROR: ${e.type} - ${e.message}');
      print('DIO RESPONSE: ${e.response?.data}');

      throw ServerException(
        e.response?.data['message'] ?? e.message ?? AppStrings.networkError,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
