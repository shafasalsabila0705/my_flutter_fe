import '../datasources/banner_remote_data_source.dart';
import '../models/banner_model.dart';

import '../../domain/repositories/banner_repository.dart';

class BannerRepositoryImpl implements BannerRepository {
  final BannerRemoteDataSource remoteDataSource;

  BannerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      return await remoteDataSource.getBanners();
    } catch (e) {
      rethrow;
    }
  }
}
