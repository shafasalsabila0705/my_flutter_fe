import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/banner_repository.dart';
import '../../data/models/banner_model.dart';
// using sl to get logger if needed or inject logger. Default clean arch pattern injects.

class GetBannersUseCase extends UseCase<List<BannerModel>, void> {
  final BannerRepository _repository;

  GetBannersUseCase(this._repository);

  @override
  Future<Stream<List<BannerModel>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<BannerModel>>();
    try {
      final banners = await _repository.getBanners();
      controller.add(banners);
      controller.close();
    } catch (e) {
      controller.addError(e);
      controller.close();
    }
    return controller.stream;
  }
}
