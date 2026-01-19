import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getLastUser();
  Future<void> clearUser();
  Future<void> cacheToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  static const cachedUserKey = 'CACHED_USER';
  static const cachedTokenKey = 'CACHED_TOKEN';

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = json.encode(user.toJson());
    await secureStorage.write(key: cachedUserKey, value: jsonString);
  }

  @override
  Future<UserModel?> getLastUser() async {
    final jsonString = await secureStorage.read(key: cachedUserKey);
    if (jsonString != null) {
      try {
        return UserModel.fromJson(json.decode(jsonString));
      } catch (e) {
        throw CacheException(e.toString());
      }
    }
    return null;
  }

  @override
  Future<void> clearUser() async {
    await secureStorage.delete(key: cachedUserKey);
  }

  @override
  Future<void> cacheToken(String token) async {
    await secureStorage.write(key: cachedTokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: cachedTokenKey);
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.delete(key: cachedTokenKey);
  }
}
