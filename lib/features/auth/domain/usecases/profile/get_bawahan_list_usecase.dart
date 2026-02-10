import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class GetBawahanListUseCase extends UseCase<List<User>, void> {
  final AuthRepository repository;

  GetBawahanListUseCase(this.repository);

  @override
  Future<Stream<List<User>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<User>>();
    try {
      final result = await repository.getBawahanList();
      controller.add(result);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}
