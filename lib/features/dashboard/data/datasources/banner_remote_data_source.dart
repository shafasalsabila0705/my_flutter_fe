import 'package:dio/dio.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../models/banner_model.dart';

abstract class BannerRemoteDataSource {
  Future<List<BannerModel>> getBanners();
}

class BannerRemoteDataSourceImpl implements BannerRemoteDataSource {
  final ApiClient apiClient;

  BannerRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await apiClient.get('/api/banner');

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final String baseUrl = apiClient.dio.options.baseUrl;

        return data.map((e) {
          final model = BannerModel.fromJson(e);
          // If image URL is relative (e.g. /uploads/...), prepend base URL
          if (model.imageUrl.isNotEmpty && !model.imageUrl.startsWith('http')) {
            final cleanPath = model.imageUrl.startsWith('/')
                ? model.imageUrl.substring(1)
                : model.imageUrl;

            return BannerModel(
              id: model.id,
              title: model.title,
              imageUrl: '$baseUrl/$cleanPath',
              linkUrl: model.linkUrl,
              isActive: model.isActive,
            );
          }
          return model;
        }).toList();
      } else {
        throw ServerException('Failed to load banners: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('Connection error: ${e.message}', originalError: e);
    } catch (e) {
      throw ServerException('Unexpected error: $e', originalError: e);
    }
  }
}
