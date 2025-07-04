import 'package:hive/hive.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../utils/app_logger.dart';

class SavedNewsService {
  static SavedNewsService? _instance;
  static const String _boxName = 'saved_news';
  
  SavedNewsService._();
  
  static SavedNewsService get instance {
    _instance ??= SavedNewsService._();
    return _instance!;
  }
  
  Box<Map>? _box;
  
  /// Initialize the saved news service
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map>(_boxName);
      AppLogger.logSuccess('SavedNewsService initialized');
    } catch (e) {
      AppLogger.logError('Failed to initialize SavedNewsService: $e');
    }
  }
  
  /// Save an article
  Future<bool> saveArticle(NewsArticle article) async {
    try {
      if (_box == null) {
        await initialize();
      }
      
      final articleData = {
        'title': article.title,
        'description': article.description,
        'url': article.url,
        'imageUrl': article.imageUrl,
        'publishedAt': article.publishedAt,
        'source': article.source,
        'savedAt': DateTime.now().toIso8601String(),
      };
      
      await _box!.put(article.url, articleData);
      AppLogger.logSuccess('Article saved: ${article.title}');
      return true;
    } catch (e) {
      AppLogger.logError('Failed to save article: $e');
      return false;
    }
  }
  
  /// Remove a saved article
  Future<bool> removeSavedArticle(String articleUrl) async {
    try {
      if (_box == null) {
        await initialize();
      }
      
      await _box!.delete(articleUrl);
      AppLogger.logSuccess('Article removed from saved');
      return true;
    } catch (e) {
      AppLogger.logError('Failed to remove saved article: $e');
      return false;
    }
  }
  
  /// Check if an article is saved
  bool isArticleSaved(String articleUrl) {
    try {
      if (_box == null) return false;
      return _box!.containsKey(articleUrl);
    } catch (e) {
      AppLogger.logError('Failed to check if article is saved: $e');
      return false;
    }
  }
  
  /// Get all saved articles
  List<NewsArticle> getSavedArticles() {
    try {
      if (_box == null) return [];
      
      final savedArticles = <NewsArticle>[];
      
      for (final articleData in _box!.values) {
        savedArticles.add(NewsArticle(
          title: articleData['title'] ?? 'No title',
          description: articleData['description'] ?? 'No description',
          url: articleData['url'] ?? '',
          imageUrl: articleData['imageUrl'],
          publishedAt: articleData['publishedAt'] ?? DateTime.now().toIso8601String(),
          source: articleData['source'] ?? 'Unknown',
        ));
      }
      
      // Sort by saved date (most recent first)
      savedArticles.sort((a, b) {
        final aData = _box!.get(a.url);
        final bData = _box!.get(b.url);
        final aSavedAt = DateTime.parse(aData?['savedAt'] ?? DateTime.now().toIso8601String());
        final bSavedAt = DateTime.parse(bData?['savedAt'] ?? DateTime.now().toIso8601String());
        return bSavedAt.compareTo(aSavedAt);
      });
      
      AppLogger.logInfo('Retrieved ${savedArticles.length} saved articles');
      return savedArticles;
    } catch (e) {
      AppLogger.logError('Failed to get saved articles: $e');
      return [];
    }
  }
  
  /// Get count of saved articles
  int getSavedArticlesCount() {
    try {
      if (_box == null) return 0;
      return _box!.length;
    } catch (e) {
      AppLogger.logError('Failed to get saved articles count: $e');
      return 0;
    }
  }
  
  /// Clear all saved articles
  Future<bool> clearAllSavedArticles() async {
    try {
      if (_box == null) {
        await initialize();
      }
      
      await _box!.clear();
      AppLogger.logSuccess('All saved articles cleared');
      return true;
    } catch (e) {
      AppLogger.logError('Failed to clear saved articles: $e');
      return false;
    }
  }
  
  /// Get saved articles by source
  List<NewsArticle> getSavedArticlesBySource(String source) {
    final allSaved = getSavedArticles();
    return allSaved.where((article) => 
      article.source.toLowerCase().contains(source.toLowerCase())
    ).toList();
  }
  
  /// Search saved articles
  List<NewsArticle> searchSavedArticles(String query) {
    final allSaved = getSavedArticles();
    final searchQuery = query.toLowerCase();
    
    return allSaved.where((article) =>
      article.title.toLowerCase().contains(searchQuery) ||
      article.description.toLowerCase().contains(searchQuery) ||
      article.source.toLowerCase().contains(searchQuery)
    ).toList();
  }
}
