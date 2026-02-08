import 'package:equatable/equatable.dart';

/// User Entity
/// Represents a user in the application.
class User extends Equatable {
  final String id;
  final String nip;
  final String name;
  final String? email;
  final String? phone;
  final String? jabatan;
  final String? bidang;
  final String? atasanId;
  final String? atasanNama;
  final String? unitKerja;

  const User({
    required this.id,
    required this.nip,
    required this.name,
    this.email,
    this.phone,
    this.jabatan,
    this.bidang,
    this.unitKerja,
    this.atasanId,
    this.atasanNama,
    this.role,
    this.token,
    this.refreshToken,
    this.photoUrl,
    this.organization,
    this.permissions = const [],
  });

  final String? role;
  final String? token;
  final String? refreshToken;
  final String? photoUrl;
  final String? organization;
  final List<String> permissions;

  @override
  List<Object?> get props => [
    id,
    nip,
    name,
    email,
    phone,
    jabatan,
    bidang,
    unitKerja,
    atasanId,
    atasanNama,
    role,
    token,
    refreshToken,
    photoUrl,
    organization,
    permissions,
  ];

  User copyWith({
    String? id,
    String? nip,
    String? name,
    String? email,
    String? phone,
    String? jabatan,
    String? bidang,
    String? unitKerja,
    String? atasanId,
    String? atasanNama,
    String? role,
    String? token,
    String? refreshToken,
    String? photoUrl,
    String? organization,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jabatan: jabatan ?? this.jabatan,
      bidang: bidang ?? this.bidang,
      unitKerja: unitKerja ?? this.unitKerja,
      atasanId: atasanId ?? this.atasanId,
      atasanNama: atasanNama ?? this.atasanNama,
      role: role ?? this.role,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      photoUrl: photoUrl ?? this.photoUrl,
      organization: organization ?? this.organization,
      permissions: permissions ?? this.permissions,
    );
  }
}
