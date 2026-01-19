import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'uuid': androidInfo.id,
          'brand': androidInfo.brand,
          'series': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'uuid': iosInfo.identifierForVendor ?? 'unknown_ios_device',
          'brand': 'Apple',
          'series': iosInfo.name,
        };
      }
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return {'uuid': 'unknown_device', 'brand': 'unknown', 'series': 'unknown'};
  }
}
