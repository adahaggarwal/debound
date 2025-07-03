import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.title,
    required super.description,
    required super.url,
    super.urlToImage,
    required super.publishedAt,
    required super.sourceName,
    super.author,
    super.content,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      sourceName: json['source']['name'] ?? '',
      author: json['author'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt.toIso8601String(),
      'source': {
        'name': sourceName,
      },
      'author': author,
      'content': content,
    };
  }
}

class NewsResponseModel extends NewsResponse {
  const NewsResponseModel({
    required super.status,
    required super.totalResults,
    required super.articles,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> articlesJson = json['articles'] ?? [];
    final List<Article> articles = articlesJson
        .map((articleJson) => ArticleModel.fromJson(articleJson))
        .toList();

    return NewsResponseModel(
      status: json['status'] ?? 'error',
      totalResults: json['totalResults'] ?? 0,
      articles: articles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'totalResults': totalResults,
      'articles': articles.map((article) => (article as ArticleModel).toJson()).toList(),
    };
  }
}