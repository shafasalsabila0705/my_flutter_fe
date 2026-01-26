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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
