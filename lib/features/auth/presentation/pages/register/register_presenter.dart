import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/usecases/register/register_usecase.dart';

class RegisterPresenter extends Presenter {
  final RegisterUseCase _registerUseCase;

  Function(String)? onRegisterSuccess;
  Function(dynamic)? onRegisterError;

  RegisterPresenter(this._registerUseCase);

  void register({
    required String nip,
    required String password,
    required String name,
    String? email,
    String? phone,
  }) {
    _registerUseCase.execute(
      _RegisterObserver(this),
      RegisterParams(
        nip: nip,
        password: password,
        name: name,
        email: email,
        phone: phone,
      ),
    );
  }

  @override
  void dispose() {
    _registerUseCase.dispose();
  }
}

class _RegisterObserver implements Observer<String> {
  final RegisterPresenter _presenter;

  _RegisterObserver(this._presenter);

  @override
  void onNext(String? response) {
    if (response != null) {
      _presenter.onRegisterSuccess?.call(response);
    }
  }

  @override
  void onComplete() {
    // Optional: handle completion
  }

  @override
  void onError(e) {
    _presenter.onRegisterError?.call(e);
  }
}
