import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  Future<String> requestPasswordReset(String nip);
  Future<String> verifyOtp(String nip, String otp);

  Future<String> resetPassword(String nip, String otp, String newPassword);
  Future<void> updateProfilePhoto(File photo);
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

        // Use Map.from to ensure mutable map
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          response.data['data'] as Map? ?? {},
        );

        // Inject tokens into map so fromJson can use them
        userData['token'] = token;
        userData['refresh_token'] = refreshToken;

        return UserModel.fromJson(userData);
      } else {
        throw ServerException(response.statusMessage ?? 'Server Error');
      }
    } on DioException catch (e) {
      // DEBUG LOGGING
      debugPrint('LOGIN DIO ERROR: ${e.type} - ${e.message}');

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
      debugPrint('DIO ERROR: ${e.type} - ${e.message}');
      debugPrint(
        'DIO REQUEST: ${e.requestOptions.baseUrl}${e.requestOptions.path}',
      );
      debugPrint('DIO RESPONSE: ${e.response?.data}');

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

  @override
  Future<String> requestPasswordReset(String nip) async {
    try {
      final response = await apiClient.post(
        '/api/forgot-password/request',
        data: {'nip': nip},
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Kode OTP telah dikirim';
      } else {
        throw ServerException(response.statusMessage ?? 'Gagal meminta OTP');
      }
    } on DioException catch (e) {
      String msg = 'Gagal meminta OTP';
      if (e.response?.data != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
      }
      throw ServerException(msg);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> verifyOtp(String nip, String otp) async {
    try {
      final response = await apiClient.post(
        '/api/forgot-password/verify',
        data: {'nip': nip, 'otp': otp},
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'OTP Valid';
      } else {
        throw ServerException('OTP Tidak Valid');
      }
    } on DioException catch (e) {
      String msg = 'OTP Tidak Valid';
      if (e.response?.data != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
      }
      throw ServerException(msg);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> resetPassword(
    String nip,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/forgot-password/reset',
        data: {'nip': nip, 'otp': otp, 'new_password': newPassword},
      );
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Password berhasil diubah';
      } else {
        throw ServerException('Gagal mereset password');
      }
    } on DioException catch (e) {
      String msg = 'Gagal mereset password';
      if (e.response?.data != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
      }
      throw ServerException(msg);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateProfilePhoto(File photo) async {
    try {
      // API expects Base64 string in JSON body, not Multipart
      final bytes = await photo.readAsBytes();
      String base64Image = base64Encode(bytes);

      // Add data URI scheme prefix if needed by backend, usually just base64 string
      // But standard for web/some APIs is "data:image/jpeg;base64,..."
      // Based on OpenAPI "Base64 string", let's try raw string first or standard header.
      // Often simple base64 is enough.
      // Let's prepend generic header for safety if the backend parses it as invalid image without it?
      // Re-reading OpenAPI: just says "Base64 string".
      // Let's try raw base64 first.

      // Wait, usually cleaner to include prefix if it's a web app backend.
      // "data:image/jpeg;base64," + base64String

      final String extension = photo.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';

      final String fullBase64 = 'data:$mimeType;base64,$base64Image';

      final response = await apiClient.put(
        '/api/asn/profile',
        data: {'foto': fullBase64},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          response.statusMessage ?? 'Gagal mengupload foto',
        );
      }
    } on DioException catch (e) {
      // Debugging
      debugPrint("UPLOAD ERROR: ${e.response?.data}");

      String msg = 'Gagal mengupload foto';
      if (e.response?.data != null && e.response!.data is Map) {
        msg = e.response!.data['message'] ?? e.response!.data['error'] ?? msg;
      }
      throw ServerException(msg);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
