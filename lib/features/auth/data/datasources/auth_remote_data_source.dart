import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../../core/utils/device_utils.dart';

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
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login(String nip, String password) async {
    try {
      final deviceInfo = await DeviceUtils.getDeviceInfo();

      final response = await apiClient.post(
        '/api/login',
        data: {
          'nip': nip,
          'password': password,
          'uuid': deviceInfo['uuid'],
          'brand': deviceInfo['brand'],
          'series': deviceInfo['series'],
        },
      );

      if (response.statusCode == 200) {
        // Response format: {"message": "Login Berhasil!", "token": "..."}
        // Since we don't get user details, we create a temporary UserModel.
        // In a real app, we would use the token to fetch the user profile.
        final token = response.data['token'] as String? ?? '';

        return UserModel(
          id: token.isNotEmpty ? token : 'generated-id',
          nip: nip,
          name: response.data['name'] ?? 'Pegawai',
          email: null,
          phone: null,
        );
      } else {
        throw ServerException(response.statusMessage ?? 'Server Error');
      }
    } on DioException catch (e) {
      // DEBUG LOGGING
      print('LOGIN DIO ERROR: ${e.type} - ${e.message}');

      String errorMessage = 'Terjadi kesalahan jaringan.';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Koneksi timeout. Coba lagi.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Tidak ada koneksi internet.';
          break;
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode == 401) {
            errorMessage = 'NIP atau Kata Sandi salah. (401)';
          } else if (statusCode == 500) {
            errorMessage = 'Server Error. (500)';
          } else {
            errorMessage =
                'Masalah Server ($statusCode): ${e.response?.statusMessage ?? "Gagal memproses."}';
          }
          break;
        default:
          errorMessage = 'Kesalahan tidak diketahui (000)';
          break;
      }

      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('Terjadi kesalahan: ${e.toString()}');
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
      final deviceInfo = await DeviceUtils.getDeviceInfo();

      final response = await apiClient.post(
        '/api/register',
        data: {
          'nip': nip,
          'password': password,
          'name': name,
          'email': email,
          'phone': phone,
          'uuid': deviceInfo['uuid'],
          'brand': deviceInfo['brand'],
          'series': deviceInfo['series'],
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
      print('DIO REQUEST: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
      print('DIO RESPONSE: ${e.response?.data}');

      throw ServerException(
        e.response?.data['message'] ?? e.message ?? AppStrings.networkError,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
