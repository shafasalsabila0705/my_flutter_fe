import '../../domain/entities/user.dart';

/// UserModel
/// Data transfer object for User.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nip,
    required super.name,
    super.email,
    super.phone,
    super.jabatan,
    super.bidang,
    super.atasanId,
    super.atasanNama,
    super.role,
    super.token,
    super.refreshToken,
    super.photoUrl,
    super.organization,
    super.unitKerja,
    super.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse Permissions
    List<String> parsedPermissions = [];
    if (json['permissions'] != null) {
      parsedPermissions = List<String>.from(json['permissions']);
    } else if (json['hak_akses'] != null) {
      parsedPermissions = List<String>.from(json['hak_akses']);
    } else {
      // Fallback Logic (Legacy Role Support)
      final role =
          (json['role'] ?? json['Role'])?.toString().toLowerCase() ?? '';
      if (role.contains('admin') || role.contains('atasan')) {
        parsedPermissions.add('view_team_history');
      }
    }

    // Generic Recursive Search Helper
    String? recursiveSearch(dynamic data, List<String> targetKeys) {
      if (data is Map) {
        // 1. Check current level for target keys
        for (var key in targetKeys) {
          final value = data[key];
          // Only return if it's a primitive value (String, num, bool), NOT a Map/List
          // And mostly importantly, not empty string
          if (value != null &&
              value is! Map &&
              value is! List &&
              value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
        // 2. Recurse into values
        for (var value in data.values) {
          var result = recursiveSearch(value, targetKeys);
          if (result != null) return result;
        }
      } else if (data is List) {
        // 3. Recurse into list items
        for (var item in data) {
          var result = recursiveSearch(item, targetKeys);
          if (result != null) return result;
        }
      }
      return null;
    }

    return UserModel(
      id:
          (json['id'] ?? json['ID'] ?? json['user_id'] ?? json['pegawai_id'])
              ?.toString() ??
          '',
      nip: json['nip']?.toString() ?? '',
      name: (json['name'] ?? json['nama'] ?? json['Nama'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: (json['phone'] ?? json['no_hp'])?.toString(),
      jabatan: (json['jabatan'] ?? json['Jabatan'])?.toString(),
      bidang: (json['bidang'] ?? json['Bidang'])?.toString(),
      atasanId: (json['atasan_id'] ?? json['atasanId'])?.toString(),
      atasanNama: (json['atasan_nama'] ?? json['atasan_name'] ?? json['Atasan'])
          ?.toString(),
      role: (json['role'] ?? json['Role'])?.toString(),
      token: json['token'],
      refreshToken: json['refresh_token'],
      photoUrl: (json['photo_url'] ?? json['foto'])?.toString(),
      // Use recursive search for organization
      organization:
          recursiveSearch(json, [
            'nama_organisasi',
            'nama_opd',
            'organization',
            'organisasi_nama',
            'organisasi', // Added as requested by user
            'Organisasi', // Added just in case
          ]) ??
          // Fallback to direct check if recursive fails (unlikely given keys above)
          (json['organisasi'] is String ? json['organisasi'] : null) ??
          (json['opd'] is String ? json['opd'] : null),

      // Use recursive search for location/unit kerja
      unitKerja: recursiveSearch(json, [
        'nama_lokasi',
        'nama_kantor',
        'unit_kerja',
        'lokasi_kerja',
        'kantor',
      ]),
      permissions: parsedPermissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nip': nip,
      'name': name,
      'email': email,
      'phone': phone,
      'jabatan': jabatan,
      'bidang': bidang,
      'atasan_id': atasanId,
      'atasan_nama': atasanNama,
      'role': role,
      'token': token,
      'refresh_token': refreshToken,
      'photo_url': photoUrl,
      'organization': organization,
      'unit_kerja': unitKerja,
    };
  }

  User toEntity() {
    return User(
      id: id,
      nip: nip,
      name: name,
      email: email,
      phone: phone,
      jabatan: jabatan,
      bidang: bidang,
      atasanId: atasanId,
      atasanNama: atasanNama,
      role: role,
      token: token,
      refreshToken: refreshToken,
      photoUrl: photoUrl,
      organization: organization,
      unitKerja: unitKerja,
      permissions: permissions,
    );
  }
}
