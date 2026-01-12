import 'package:flutter/foundation.dart';
import '../../features/auth/domain/entities/user.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  bool get isLoggedIn => _currentUser != null;

  void setUser(User user, {String? token}) {
    _currentUser = user;
    if (token != null) _token = token;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
