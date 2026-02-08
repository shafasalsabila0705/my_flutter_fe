import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase extends UseCase<void, void> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  Future<Stream<void>> buildUseCaseStream(void params) async {
    final controller = StreamController<void>();
    try {
      await _repository.logout();
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}
