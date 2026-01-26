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

  const User({
    required this.id,
    required this.nip,
    required this.name,
    this.email,
    this.phone,
    this.jabatan,
    this.bidang,
    this.atasanId,
    this.atasanNama,
    this.role,
    this.token,
    this.refreshToken,
  });

  final String? role;
  final String? token;
  final String? refreshToken;

  @override
  List<Object?> get props => [
    id,
    nip,
    name,
    email,
    phone,
    jabatan,
    bidang,
    atasanId,
    atasanNama,
    role,
    token,
    refreshToken,
  ];
}
