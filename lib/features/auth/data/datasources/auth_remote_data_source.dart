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
  Future<UserModel> getProfile();
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> updateAtasan(String atasanId);
  Future<List<UserModel>> getAtasanList();
  Future<void> changePassword(String oldPassword, String newPassword);
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
          'device_id': deviceInfo['uuid'], // Mapped from uuid to device_id
          'brand': deviceInfo['brand'],
          'series': deviceInfo['series'],
        },
      );

      if (response.statusCode == 200) {
        // Response format: {"message": "Login Berhasil", "token": "...", "refresh_token": "...", "data": {...}}
        final token = response.data['token'] as String? ?? '';
        final refreshToken = response.data['refresh_token'] as String? ?? '';
        final userData = response.data['data'] as Map<String, dynamic>? ?? {};

        return UserModel(
          id: token.isNotEmpty ? token : 'generated-id',
          nip: userData['nip'] ?? nip,
          name: userData['nama'] ?? userData['name'] ?? 'Pegawai',
          email: userData['email'],
          phone: userData['no_hp'] ?? userData['phone'],
          jabatan: userData['jabatan'],
          bidang: userData['bidang'],
          atasanId: (userData['atasan_id'] ?? userData['atasanId'])?.toString(),
          atasanNama: (userData['atasan_nama'] ?? userData['atasan_name'])
              ?.toString(),
          role: (userData['role'] ?? userData['Role'])?.toString(),
          token: token,
          refreshToken: refreshToken,
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

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await apiClient.put(
        '/api/asn/password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      if (response.statusCode != 200) {
        String msg = 'Gagal mengubah sandi';
        if (response.data is Map) {
          msg = response.data['message'] ?? msg;
        } else if (response.data is String) {
          msg = response.data;
        }
        throw ServerException(msg);
      }
    } on DioException catch (e) {
      String msg = 'Gagal mengubah sandi';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
        } else if (e.response!.data is String) {
          msg = e.response!.data;
        }
      }
      throw ServerException(msg);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get('/api/asn/profile');
      if (response.statusCode == 200) {
        // Assuming response data is directly the user object or wrapped in 'data'
        final data = response.data['data'] ?? response.data;
        return UserModel.fromJson(data);
      } else {
        throw ServerException('Gagal mengambil profil');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await apiClient.put('/api/asn/profile', data: data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateAtasan(String atasanId) async {
    try {
      await apiClient.post(
        '/api/asn/atasan',
        data: {'atasan_id': int.tryParse(atasanId) ?? atasanId},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UserModel>> getAtasanList() async {
    try {
      final response = await apiClient.get('/api/asn/atasan-list');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => UserModel.fromJson(e)).toList();
      } else {
        throw ServerException('Gagal mengambil daftar atasan');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
