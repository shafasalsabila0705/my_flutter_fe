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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nip: json['nip'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nip': nip, 'name': name, 'email': email, 'phone': phone};
  }

  User toEntity() {
    return User(id: id, nip: nip, name: name, email: email, phone: phone);
  }
}
