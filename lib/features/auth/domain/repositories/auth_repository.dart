import 'dart:io';
import '../entities/user.dart';

/// AuthRepository Interface
/// Defines the contract for authentication operations.
abstract class AuthRepository {
  /// Logs in the user with the given [nip] and [password].
  /// Returns a [User] on success.
  /// Throws an exception on failure.
  Future<User> login(String nip, String password);

  /// Fetches the user profile from remote
  Future<User> getProfile();

  /// Updates the user profile
  Future<void> updateProfile(Map<String, dynamic> data);

  /// Updates the user's supervisor (Atasan)
  Future<void> updateAtasan(String atasanId);

  /// Logout current user
  Future<void> logout();

  /// Get currently authenticated user
  ///
  /// Returns null if no user is logged in
  Future<User?> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Fetch list of supervisors (Atasan)
  Future<List<User>> getAtasanList();

  /// Fetch list of subordinates (Bawahan)
  Future<List<User>> getBawahanList();

  /// Change User Password
  Future<void> changePassword(String oldPassword, String newPassword);

  Future<String> requestPasswordReset(String nip);
  Future<String> verifyOtp(String nip, String otp);
  Future<String> resetPassword(String nip, String otp, String newPassword);

  /// Update Profile Photo
  Future<void> updateProfilePhoto(File photo);
}
