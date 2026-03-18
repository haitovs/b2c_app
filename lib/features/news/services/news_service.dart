import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

/// News item model
class NewsItem {
  final int id;
  final String header;
  final String description;
  final String? category;
  final String? photo;
  final String? content;
  final DateTime createdAt;

  NewsItem({
    required this.id,
    required this.header,
    required this.description,
    this.category,
    this.photo,
    this.content,
    required this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] ?? 0,
      header: json['header'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
      photo: json['photo'],
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Get full image URL (now from B2C backend)
  String get imageUrl {
    if (photo == null || photo!.isEmpty) return '';
    if (photo!.startsWith('http')) return photo!;
    return '${AppConfig.b2cApiBaseUrl}$photo';
  }
}

/// Service for fetching news from B2C backend
class NewsService {
  final ApiClient _api;

  NewsService(this._api);

  /// Fetch news with pagination (B2C-visible articles only)
  Future<List<NewsItem>> fetchNews({
    int skip = 0,
    int limit = 12,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'visibility': 'B2C',
    };

    final result = await _api.get<List<dynamic>>(
      '/api/v1/content/news',
      queryParams: queryParams,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.map((json) => NewsItem.fromJson(json)).toList();
    }
    return [];
  }

  /// Get single news item by ID
  Future<NewsItem?> getNews(int id) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/content/news/$id',
    );

    if (result.isSuccess && result.data != null) {
      return NewsItem.fromJson(result.data!);
    }
    return null;
  }
}
