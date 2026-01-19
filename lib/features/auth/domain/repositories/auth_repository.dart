import '../entities/user.dart';

/// AuthRepository Interface
/// Defines the contract for authentication operations.
abstract class AuthRepository {
  /// Logs in the user with the given [nip] and [password].
  /// Returns a [User] on success.
  /// Throws an exception on failure.
  Future<User> login(String nip, String password);

  /// Registers a new user.
  Future<String> register({
    required String nip,
    required String password,
    required String name,
    String? email,
    String? phone,
  });

  /// Logout current user
  Future<void> logout();

  /// Get currently authenticated user
  ///
  /// Returns null if no user is logged in
  Future<User?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
