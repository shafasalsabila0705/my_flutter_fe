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
    state = state.copyWith(currentUser: user);
  }

  void clearUser() {
    state = const UserState();
  }

  bool get isLoggedIn => state.currentUser != null;
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
