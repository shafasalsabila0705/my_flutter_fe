import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image/image.dart' as img; // Added for compression
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';
import '../models/perizinan_model.dart';
import '../models/location_check_model.dart';
import '../models/schedule_item_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceModel> checkIn(double lat, double long, {String? reason});
  Future<AttendanceModel> checkInWithPhoto(
    double lat,
    double long,
    File photo, {
    String? reason,
  });
  Future<AttendanceModel> checkOut(double lat, double long, {String? reason});
  Future<AttendanceModel> checkOutWithPhoto(
    double lat,
    double long,
    File photo, {
    String? reason,
  });
  Future<List<AttendanceModel>> getHistory(); // /api/kehadiran/riwayat
  Future<AttendanceRecapModel> getRecap(
    String month,
    String year,
  ); // /api/kehadiran/rekap
  Future<AttendanceRecapModel> getTeamRecap(
    String month,
    String year,
  ); // /api/kehadiran/rekap with scope=team
  Future<Map<String, dynamic>>
  getTodayStatus(); // /api/kehadiran/status-hari-ini
  Future<List<AttendanceModel>> getTeamHistory(
    String month,
    String year,
  ); // /api/kehadiran/riwayat with scope=team
  Future<List<PerizinanModel>> getCorrectionHistory(); // /api/koreksi/riwayat
  Future<void> submitCorrection({
    required String tanggal,
    required String alasan,
    String tipe = 'KOREKSI',
    File? bukti,
  });
  Future<void> cancelCorrection(String id);
  Future<void> updateCorrection({
    required String id,
    required String tanggal,
    required String alasan,
    File? bukti,
  });
  Future<List<ScheduleItemModel>> getMonthlySchedule(String month, String year);
  Future<LocationCheckModel> checkLocation(double lat, double long);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AttendanceModel> checkInWithPhoto(
    double lat,
    double long,
    File photo, {
    String? reason,
  }) async {
    // 1. Call Regular Check-In First (To ensure entry in `kehadirans`)
    // We try this first. If it fails (e.g. server error), we might still want to try correction?
    // User requirement: "tetap harus masuk ke db kehadirans".
    // So we force a check-in attempt.
    AttendanceModel? checkInResult;
    try {
      checkInResult = await checkIn(lat, long);
    } catch (e) {
      debugPrint("Regular CheckIn failed during OutsideRadius flow: $e");
      // Continue to correction? Or Throw?
      // If `checkIn` fails, the requirement "must exist in database" fails.
      // However, usually "Outside Radius" implies CheckIn *would* fail if validation is strict.
      // But BE team said "seharusnya pas dia checkin tu langsung aja terhitung".
      // This suggests we should suppress the error and proceed to upload proof,
      // OR rethrow if it's a critical system error.
      // Let's proceed to allow the Correction (Proof) to be uploaded at minimum.
    }

    try {
      // 2. Compress Image Logic (Max 1MB)
      File finalPhoto = photo;
      int sizeInBytes = await finalPhoto.length();
      int quality = 85;

      // Target: Under 1MB (1024 * 1024 bytes)
      while (sizeInBytes > 1024 * 1024 && quality > 10) {
        final decodedImage = img.decodeImage(await finalPhoto.readAsBytes());
        if (decodedImage == null) break;

        final compressedBytes = img.encodeJpg(decodedImage, quality: quality);

        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(compressedBytes);

        finalPhoto = tempFile;
        sizeInBytes = await finalPhoto.length();
        quality -= 15;
      }

      String fileName = finalPhoto.path.split('/').last;

      // 3. Prepare FormData for Correction API (Luar Radius)
      FormData formData = FormData.fromMap({
        'tanggal_kehadiran': DateTime.now().toIso8601String().split('T')[0],
        'tipe_koreksi': 'LUAR_RADIUS',
        'is_lokasi': true,
        'alasan': reason ?? 'Presensi Luar Radius (Melalui Aplikasi)',
        'latitude': lat,
        'longitude': long,
        'file_bukti': await MultipartFile.fromFile(
          finalPhoto.path,
          filename: fileName,
        ),
      });

      // 4. Call Correction Endpoint
      final response = await apiClient.post(
        '/api/koreksi/ajukan',
        data: formData,
      );

      if (response.statusCode == 200) {
        // Use checkInResult if available, otherwise placeholder
        if (checkInResult != null) {
          // Verify if we should override status to pending?
          // Usually correction implies pending.
          return checkInResult.copyWith(
            status: 'MENUNGGU VERIFIKASI (DL)',
          ); // Custom hint
        }

        return const AttendanceModel(
          status: 'MENUNGGU VERIFIKASI',
          checkInTime: 'Pending',
          date: '-',
        );
      } else {
        throw ServerException(
          response.statusMessage ?? 'Gagal mengajukan presensi',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat upload foto';
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMessage =
              data['message'] ??
              data['error'] ??
              data['errors']?.toString() ??
              'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
        } else if (data is String) {
          errorMessage = data;
        }
      }
      throw ServerException(errorMessage);
    }
  }

  @override
  Future<AttendanceModel> checkOutWithPhoto(
    double lat,
    double long,
    File photo, {
    String? reason,
  }) async {
    // 1. Call Regular Check-Out First
    AttendanceModel? checkOutResult;
    try {
      checkOutResult = await checkOut(lat, long);
    } catch (e) {
      debugPrint("Regular CheckOut failed during OutsideRadius flow: $e");
    }

    try {
      // 2. Compress Image Logic (Max 1MB)
      File finalPhoto = photo;
      int sizeInBytes = await finalPhoto.length();
      int quality = 85;

      while (sizeInBytes > 1024 * 1024 && quality > 10) {
        final decodedImage = img.decodeImage(await finalPhoto.readAsBytes());
        if (decodedImage == null) break;

        final compressedBytes = img.encodeJpg(decodedImage, quality: quality);

        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(compressedBytes);

        finalPhoto = tempFile;
        sizeInBytes = await finalPhoto.length();
        quality -= 15;
      }

      String fileName = finalPhoto.path.split('/').last;

      // 3. Prepare FormData for Correction API (Luar Radius)
      FormData formData = FormData.fromMap({
        'tanggal_kehadiran': DateTime.now().toIso8601String().split('T')[0],
        'tipe_koreksi': 'LUAR_RADIUS',
        'is_lokasi': true,
        'alasan': reason ?? 'Presensi Pulang Luar Radius (Melalui Aplikasi)',
        'latitude': lat,
        'longitude': long,
        'file_bukti': await MultipartFile.fromFile(
          finalPhoto.path,
          filename: fileName,
        ),
      });

      // 4. Call Correction Endpoint
      final response = await apiClient.post(
        '/api/koreksi/ajukan',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (checkOutResult != null) {
          return checkOutResult.copyWith(status: 'MENUNGGU VERIFIKASI (DL)');
        }

        return const AttendanceModel(
          status: 'MENUNGGU VERIFIKASI',
          checkInTime: '-',
          checkOutTime: 'Pending',
          date: '-',
        );
      } else {
        throw ServerException(
          response.statusMessage ?? 'Gagal mengajukan presensi pulang',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat upload foto pulang';
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMessage =
              data['message'] ??
              data['error'] ??
              'Error ${e.response?.statusCode}';
        }
      }
      throw ServerException(errorMessage);
    }
  }

  @override
  Future<AttendanceModel> checkIn(
    double lat,
    double long, {
    String? reason,
  }) async {
    try {
      // 1. Perform Check-In
      final response = await apiClient.post(
        '/api/kehadiran/checkin',
        data: {'latitude': lat, 'longitude': long},
      );

      if (response.statusCode == 200) {
        // 2. If valid and reason provided (Late), submit correction
        if (reason != null && reason.isNotEmpty) {
          try {
            await submitCorrection(
              tanggal: DateTime.now().toIso8601String().split('T')[0],
              alasan: reason,
              tipe: 'TERLAMBAT',
            );
          } catch (e) {
            debugPrint("Warning: Failed to submit Late Correction: $e");
            // We don't throw here because the main Check-In succeeded.
          }
        }

        final data = response.data;
        return AttendanceModel.fromJson(data);
      } else {
        throw ServerException(response.statusMessage ?? 'Check-in Gagal');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ??
            e.message ??
            'Terjadi kesalahan check-in',
      );
    }
  }

  @override
  Future<AttendanceModel> checkOut(
    double lat,
    double long, {
    String? reason,
  }) async {
    try {
      // 1. Perform Check-Out
      final response = await apiClient.post(
        '/api/kehadiran/checkout',
        data: {'latitude': lat, 'longitude': long},
      );

      if (response.statusCode == 200) {
        // 2. If valid and reason provided (Early Leave), submit correction
        if (reason != null && reason.isNotEmpty) {
          try {
            await submitCorrection(
              tanggal: DateTime.now().toIso8601String().split('T')[0],
              alasan: reason,
              tipe: 'PULANG_CEPAT',
            );
          } catch (e) {
            debugPrint("Warning: Failed to submit Early Leave Correction: $e");
          }
        }

        return AttendanceModel.fromJson(response.data);
      } else {
        throw ServerException(response.statusMessage ?? 'Check-out Gagal');
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ??
            e.message ??
            'Terjadi kesalahan check-out',
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getHistory() async {
    try {
      final response = await apiClient.get('/api/kehadiran/riwayat');

      if (response.statusCode == 200) {
        final List list =
            response.data['data'] ??
            []; // Adjust based on actual response wrapper
        return list.map((e) => AttendanceModel.fromJson(e)).toList();
      } else {
        throw ServerException('Gagal mengambil riwayat');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil riwayat');
    }
  }

  @override
  Future<AttendanceRecapModel> getRecap(String month, String year) async {
    try {
      final response = await apiClient.get(
        '/api/kehadiran/rekap',
        queryParameters: {'bulan': month, 'tahun': year},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return AttendanceRecapModel.fromJson(data);
      } else {
        throw ServerException('Gagal mengambil rekap');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil rekap');
    }
  }

  @override
  Future<AttendanceRecapModel> getTeamRecap(String month, String year) async {
    try {
      // Updated to use the correct endpoint discovered by user
      final response = await apiClient.get(
        '/api/atasan/reports/monthly',
        queryParameters: {'bulan': month, 'tahun': year},
      );

      debugPrint("🚀 TEAM RECAP (NEW API) RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        var responseData = response.data;
        var data = responseData['data'];

        // Handle case where 'data' might be null or not a map
        if (data == null || data is! Map) {
          if (responseData is Map) {
            data = responseData; // Treat root as data
          } else {
            data = <String, dynamic>{};
          }
        }

        // Merge potential root lists into data map if missing
        if (data is Map<String, dynamic>) {
          if (data['details'] == null && responseData is Map) {
            if (responseData['details'] != null) {
              data['details'] = responseData['details'];
            }
            if (responseData['histories'] != null) {
              data['details'] = responseData['histories'];
            }
            if (responseData['list'] != null) {
              data['details'] = responseData['list'];
            }
            // Check for list directly in data if structure is different
            if (responseData is List) {
              data['details'] = responseData;
            }
          }
        }

        // If 'data' is a List, we should pass the PARENT (responseData) to fromJson
        // because fromJson expects a Map and checks for 'data' key inside it.
        if (data is List) {
          return AttendanceRecapModel.fromJson(responseData);
        }

        return AttendanceRecapModel.fromJson(Map<String, dynamic>.from(data));
      } else {
        throw ServerException('Gagal mengambil rekap tim');
      }
    } on DioException catch (e) {
      debugPrint("❌ TEAM RECAP ERROR: ${e.message}");
      if (e.response != null) {
        debugPrint("❌ ERROR DATA: ${e.response?.data}");
      }
      throw ServerException(e.message ?? 'Gagal mengambil rekap tim');
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayStatus() async {
    try {
      final response = await apiClient.get('/api/kehadiran/status-hari-ini');
      if (response.statusCode == 200) {
        return response.data ?? {};
      } else {
        throw ServerException('Gagal mengambil status hari ini');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil status');
    }
  }

  @override
  Future<List<AttendanceModel>> getTeamHistory(
    String month,
    String year,
  ) async {
    try {
      // Reverting to 'riwayat' as 'bawahan' was 404.
      // Trying to send multiple params that might trigger the filter.
      final response = await apiClient.get(
        '/api/kehadiran/riwayat',
        queryParameters: {
          'bulan': month,
          'tahun': year,
          'scope': 'team',
          'mode': 'bawahan', // Additional guess
        },
      );

      debugPrint("🚀 TEAM HISTORY RESPONSE: ${response.data}");

      if (response.statusCode == 200) {
        final List list =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);
        return list.map((e) => AttendanceModel.fromJson(e)).toList();
      } else {
        throw ServerException('Gagal mengambil riwayat tim');
      }
    } on DioException catch (e) {
      debugPrint("❌ TEAM HISTORY ERROR: ${e.message}");
      throw ServerException(e.message ?? 'Gagal mengambil riwayat tim');
    }
  }

  @override
  Future<List<PerizinanModel>> getCorrectionHistory() async {
    try {
      final response = await apiClient.get('/api/koreksi/riwayat');

      if (response.statusCode == 200) {
        debugPrint("🚀 CORRECTION HISTORY RESPONSE: ${response.data}"); // DEBUG
        final List list =
            (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : (response.data is List ? response.data : []);

        // Map Correction JSON to PerizinanModel
        return list.map((e) => PerizinanModel.fromCorrectionJson(e)).toList();
      } else {
        throw ServerException('Gagal mengambil riwayat koreksi');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gagal mengambil riwayat koreksi');
    }
  }

  @override
  Future<void> submitCorrection({
    required String tanggal,
    required String alasan,
    String tipe = 'KOREKSI',
    File? bukti,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'tanggal_kehadiran': tanggal,
        'tipe_koreksi': tipe,
        'alasan': alasan,
      };

      if (bukti != null) {
        File finalPhoto = bukti;
        int sizeInBytes = await finalPhoto.length();
        int quality = 85;

        while (sizeInBytes > 1024 * 1024 && quality > 10) {
          final decodedImage = img.decodeImage(await finalPhoto.readAsBytes());
          if (decodedImage == null) break;
          final compressedBytes = img.encodeJpg(decodedImage, quality: quality);
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File(
            '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await tempFile.writeAsBytes(compressedBytes);
          finalPhoto = tempFile;
          sizeInBytes = await finalPhoto.length();
          quality -= 15;
        }

        String fileName = finalPhoto.path.split('/').last;

        var formData = FormData.fromMap({
          ...dataMap,
          'file_bukti': await MultipartFile.fromFile(
            finalPhoto.path,
            filename: fileName,
          ),
        });

        final response = await apiClient.post(
          '/api/koreksi/ajukan',
          data: formData,
        );

        if (response.statusCode != 200) {
          throw ServerException(
            response.statusMessage ?? 'Gagal mengajukan koreksi',
          );
        }
      } else {
        var formData = FormData.fromMap(dataMap);
        final response = await apiClient.post(
          '/api/koreksi/ajukan',
          data: formData,
        );

        if (response.statusCode != 200) {
          throw ServerException(
            response.statusMessage ?? 'Gagal mengajukan koreksi',
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal mengajukan koreksi';
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMessage = data['message'] ?? errorMessage;
        }
      }
      throw ServerException(errorMessage);
    }
  }

  @override
  Future<LocationCheckModel> checkLocation(double lat, double long) async {
    try {
      final response = await apiClient.post(
        '/api/kehadiran/check-location',
        data: {'latitude': lat, 'longitude': long},
      );

      if (response.statusCode == 200) {
        return LocationCheckModel.fromJson(response.data);
      } else {
        throw ServerException(
          response.statusMessage ?? 'Gagal mengecek lokasi',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? e.message ?? 'Gagal mengecek lokasi',
      );
    }
  }

  @override
  Future<void> cancelCorrection(String id) async {
    try {
      final response = await apiClient.delete('/api/koreksi/ajukan/$id');
      if (response.statusCode != 200) {
        throw ServerException(response.statusMessage ?? 'Gagal membatalkan');
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal membatalkan koreksi';
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
          if (data['errors'] != null) {
            errorMessage += ': ${data['errors']}';
          }
        } else if (data is String) {
          errorMessage = data;
        }
      }
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateCorrection({
    required String id,
    required String tanggal,
    required String alasan,
    File? bukti,
  }) async {
    try {
      dynamic requestData;
      if (bukti != null) {
        requestData = FormData.fromMap({
          'tanggal_kehadiran': tanggal,
          'alasan': alasan,
          'file_bukti': await MultipartFile.fromFile(bukti.path),
        });
      } else {
        requestData = {'tanggal_kehadiran': tanggal, 'alasan': alasan};
      }

      final response = await apiClient.put(
        '/api/koreksi/ajukan/$id',
        data: requestData,
      );

      if (response.statusCode != 200) {
        throw ServerException(response.statusMessage ?? 'Gagal mengupdate');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ScheduleItemModel>> getMonthlySchedule(String month, String year) async {
    try {
      final response = await apiClient.get(
        '/api/jadwal/saya',
        queryParameters: {
          'bulan': month,
          'tahun': year,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ScheduleItemModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.statusMessage ?? 'Gagal memuat jadwal');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

