import 'package:equatable/equatable.dart';

/// User Entity
/// Represents a user in the application.
class User extends Equatable {
  final String id;
  final String nip;
  final String name;
  final String? email;
  final String? phone;

  const User({
    required this.id,
    required this.nip,
    required this.name,
    this.email,
    this.phone,
  });

  @override
  List<Object?> get props => [id, nip, name, email, phone];
}
