import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user.dart';

class UserState {
  final User? currentUser;
  final bool isLoading;

  const UserState({this.currentUser, this.isLoading = false});

  UserState copyWith({User? currentUser, bool? isLoading}) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState());

  void setUser(User user) {
    // Smart Update: Preserve organization and unitKerja if the new object has them missing
    // This handles the case where Login API returns full data, but GetProfile API returns empty/broken organization data
    User mergedUser = user;

    if (state.currentUser != null) {
      final old = state.currentUser!;

      String? organization = user.organization;
      String? unitKerja = user.unitKerja;

      // If new organization is missing/empty, but old one exists, use old one
      if ((organization == null || organization.isEmpty) &&
          (old.organization != null && old.organization!.isNotEmpty)) {
        organization = old.organization;
      }

      // If new unitKerja is missing/empty, but old one exists, use old one
      if ((unitKerja == null || unitKerja.isEmpty) &&
          (old.unitKerja != null && old.unitKerja!.isNotEmpty)) {
        unitKerja = old.unitKerja;
      }

      // Apply merge if changes detected
      if (organization != user.organization || unitKerja != user.unitKerja) {
        mergedUser = user.copyWith(
          organization: organization,
          unitKerja: unitKerja,
        );
      }
    }

    state = state.copyWith(currentUser: mergedUser);
  }

  void clearUser() {
    state = const UserState();
  }

  bool get isLoggedIn => state.currentUser != null;
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
