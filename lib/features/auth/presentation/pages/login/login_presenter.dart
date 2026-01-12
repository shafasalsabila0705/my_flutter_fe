import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/usecases/login/login_usecase.dart';
import '../../../domain/entities/user.dart';

class LoginPresenter extends Presenter {
  final LoginUseCase _loginUseCase;

  Function(User)? onLoginUnsuccessful;
  Function(User)? onLoginSuccess;
  Function(dynamic)? onLoginError;

  LoginPresenter(this._loginUseCase);

  void login(String nip, String password) {
    _loginUseCase.execute(_LoginObserver(this), LoginParams(nip, password));
  }

  @override
  void dispose() {
    _loginUseCase.dispose();
  }
}

class _LoginObserver implements Observer<User> {
  final LoginPresenter _presenter;

  _LoginObserver(this._presenter);

  @override
  void onNext(User? response) {
    if (response != null) {
      _presenter.onLoginSuccess?.call(response);
    }
  }

  @override
  void onComplete() {
    // Optional: handle completion
  }

  @override
  void onError(e) {
    _presenter.onLoginError?.call(e);
  }
}
