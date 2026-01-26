import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['judul'] ?? 'No Title',
      imageUrl:
          json['foto'] ?? json['gambar'] ?? json['image'] ?? json['url'] ?? '',
      linkUrl: json['link'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  @override
  List<Object?> get props => [id, title, imageUrl, linkUrl, isActive];
}
