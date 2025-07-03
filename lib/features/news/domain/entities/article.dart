import 'package:equatable/equatable.dart';

class Article extends Equatable {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String sourceName;
  final String? author;
  final String? content;

  const Article({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.sourceName,
    this.author,
    this.content,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        url,
        urlToImage,
        publishedAt,
        sourceName,
        author,
        content,
      ];
}

class NewsResponse extends Equatable {
  final String status;
  final int totalResults;
  final List<Article> articles;

  const NewsResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  @override
  List<Object> get props => [status, totalResults, articles];
}