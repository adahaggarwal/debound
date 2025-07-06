import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/saved_news_service.dart';
import '../../../../core/services/cache_service.dart';

// Events
abstract class NewsEvent extends Equatable {
  const NewsEvent();
  
  @override
  List<Object> get props => [];
}

class GetTopHeadlinesEvent extends NewsEvent {}

class TestNewsApiEvent extends NewsEvent {}

class GetNewsByCategoryEvent extends NewsEvent {
  final String category;
  
  const GetNewsByCategoryEvent(this.category);
  
  @override
  List<Object> get props => [category];
}

class SearchNewsEvent extends NewsEvent {
  final String query;
  
  const SearchNewsEvent(this.query);
  
  @override
  List<Object> get props => [query];
}

class SaveArticleEvent extends NewsEvent {
  final NewsArticle article;
  
  const SaveArticleEvent(this.article);
  
  @override
  List<Object> get props => [article];
}

class RemoveSavedArticleEvent extends NewsEvent {
  final String articleUrl;
  
  const RemoveSavedArticleEvent(this.articleUrl);
  
  @override
  List<Object> get props => [articleUrl];
}

class GetSavedArticlesEvent extends NewsEvent {}

class RefreshNewsEvent extends NewsEvent {}

class LoadMoreNewsEvent extends NewsEvent {}

class LoadCachedNewsEvent extends NewsEvent {}

// States
abstract class NewsState extends Equatable {
  const NewsState();
  
  @override
  List<Object> get props => [];
}

class NewsInitialState extends NewsState {}

class NewsLoadingState extends NewsState {}

class NewsLoadingMoreState extends NewsState {
  final List<NewsArticle> existingArticles;
  
  const NewsLoadingMoreState(this.existingArticles);
  
  @override
  List<Object> get props => [existingArticles];
}

class NewsLoadedState extends NewsState {
  final List<NewsArticle> articles;
  final bool isSavedArticlesView;
  final DateTime timestamp;
  final bool hasMoreData;
  final int currentPage;
  
  NewsLoadedState(
    this.articles, {
    this.isSavedArticlesView = false,
    this.hasMoreData = true,
    this.currentPage = 1,
  }) : timestamp = DateTime.now();
  
  @override
  List<Object> get props => [articles, isSavedArticlesView, timestamp, hasMoreData, currentPage];
}

class NewsSavedState extends NewsState {
  final String message;
  
  const NewsSavedState(this.message);
  
  @override
  List<Object> get props => [message];
}

class NewsErrorState extends NewsState {
  final String message;
  
  const NewsErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}

// Data Models
class NewsArticle extends Equatable {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final String publishedAt;
  final String source;
  
  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.source,
  });
  
  @override
  List<Object?> get props => [title, description, url, imageUrl, publishedAt, source];
}

// BLoC
class NewsBloc extends Bloc<NewsEvent, NewsState> {
  String _currentCategory = 'general';
  String? _currentSearchQuery;
  int _currentPage = 1;
  
  NewsBloc() : super(NewsInitialState()) {
    on<GetTopHeadlinesEvent>(_onGetTopHeadlines);
    on<GetNewsByCategoryEvent>(_onGetNewsByCategory);
    on<SearchNewsEvent>(_onSearchNews);
    on<RefreshNewsEvent>(_onRefreshNews);
    on<LoadMoreNewsEvent>(_onLoadMoreNews);
    on<LoadCachedNewsEvent>(_onLoadCachedNews);
    on<TestNewsApiEvent>(_onTestNewsApi);
    on<SaveArticleEvent>(_onSaveArticle);
    on<RemoveSavedArticleEvent>(_onRemoveSavedArticle);
    on<GetSavedArticlesEvent>(_onGetSavedArticles);
    
    // Initialize saved news service
    _initializeSavedNewsService();
  }
  
  Future<void> _initializeSavedNewsService() async {
    await SavedNewsService.instance.initialize();
  }
  
  Future<void> _onGetTopHeadlines(
    GetTopHeadlinesEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Getting top headlines...');
    emit(NewsLoadingState());
    
    // Reset to default category when getting top headlines
    _currentCategory = 'general';
    _currentSearchQuery = null;
    _currentPage = 1;
    
    try {
      AppLogger.logNews('Attempting to fetch top headlines...');
      
      // Test with real API call
      final response = await NetworkClient.instance.getTopHeadlines(
        category: _currentCategory,
        page: _currentPage,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Top headlines received successfully');
        AppLogger.logNews('API Response: ${data.toString()}');
        AppLogger.logNews('Articles count: ${data['totalResults']}');
        
        final articles = <NewsArticle>[];
        final articlesData = data['articles'] as List;
        
        for (final articleData in articlesData) {
          articles.add(NewsArticle(
            title: articleData['title'] ?? 'No title',
            description: articleData['description'] ?? 'No description',
            url: articleData['url'] ?? '',
            imageUrl: articleData['urlToImage'],
            publishedAt: articleData['publishedAt'] ?? DateTime.now().toIso8601String(),
            source: articleData['source']['name'] ?? 'Unknown',
          ));
        }
        
        AppLogger.logSuccess('Parsed ${articles.length} articles');
        
        final hasMoreData = articles.length >= 20; // Assuming 20 articles per page
        emit(NewsLoadedState(
          articles, 
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
        ));
        
        // Cache the news data
        await CacheService.instance.cacheNewsData(articles, page: _currentPage);
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      AppLogger.logError('Failed to get top headlines: $e');
      
      // Try to load cached data first
      final cachedArticles = CacheService.instance.getCachedNewsData();
      if (cachedArticles.isNotEmpty) {
        AppLogger.logWarning('Using cached news data');
        final cachedPage = CacheService.instance.getCurrentNewsPage();
        emit(NewsLoadedState(
          cachedArticles,
          hasMoreData: true,
          currentPage: cachedPage,
        ));
        return;
      }
      
      // Fallback to mock data for UI testing
      AppLogger.logWarning('Using mock data for UI testing');
      final articles = _getMockArticles();
      emit(NewsLoadedState(
        articles,
        hasMoreData: true,
        currentPage: 1,
      ));
    }
  }
  
  Future<void> _onGetNewsByCategory(
    GetNewsByCategoryEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Getting news for category: ${event.category}');
    emit(NewsLoadingState());
    
    // Update current category and clear search query
    _currentCategory = event.category;
    _currentSearchQuery = null;
    _currentPage = 1;
    
    try {
      AppLogger.logNews('Attempting to fetch news for category: ${event.category}');
      
      // Use real API call for category news
      final response = await NetworkClient.instance.getTopHeadlines(
        category: event.category,
        page: _currentPage,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Category news received successfully');
        AppLogger.logNews('API Response: ${data.toString()}');
        AppLogger.logNews('Articles count for ${event.category}: ${data['totalResults']}');
        
        final articles = <NewsArticle>[];
        final articlesData = data['articles'] as List;
        
        for (final articleData in articlesData) {
          articles.add(NewsArticle(
            title: articleData['title'] ?? 'No title',
            description: articleData['description'] ?? 'No description',
            url: articleData['url'] ?? '',
            imageUrl: articleData['urlToImage'],
            publishedAt: articleData['publishedAt'] ?? DateTime.now().toIso8601String(),
            source: articleData['source']['name'] ?? 'Unknown',
          ));
        }
        
        AppLogger.logSuccess('Parsed ${articles.length} articles for category: ${event.category}');
        
        final hasMoreData = articles.length >= 20;
        emit(NewsLoadedState(
          articles,
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
        ));
        
        // Cache the news data
        await CacheService.instance.cacheNewsData(articles, page: _currentPage);
      } else {
        throw Exception('Failed to load news for category: ${event.category}');
      }
    } catch (e) {
      AppLogger.logError('Failed to get news for category ${event.category}: $e');
      
      // Fallback to mock data with category context
      AppLogger.logWarning('Using mock data for category: ${event.category}');
      final articles = _getMockArticlesForCategory(event.category);
      emit(NewsLoadedState(
        articles,
        hasMoreData: true,
        currentPage: 1,
      ));
    }
  }
  
  Future<void> _onSearchNews(
    SearchNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Searching news for query: ${event.query}');
    emit(NewsLoadingState());
    
    // Update search query and clear category
    _currentSearchQuery = event.query;
    _currentCategory = 'general'; // Reset to general for search
    _currentPage = 1;
    
    try {
      AppLogger.logNews('Attempting to search news for: ${event.query}');
      
      // Use real API call for search
      final response = await NetworkClient.instance.searchNews(
        query: event.query,
        page: _currentPage,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Search results received successfully');
        AppLogger.logNews('API Response: ${data.toString()}');
        AppLogger.logNews('Search results count for "${event.query}": ${data['totalResults']}');
        
        final articles = <NewsArticle>[];
        final articlesData = data['articles'] as List;
        
        for (final articleData in articlesData) {
          articles.add(NewsArticle(
            title: articleData['title'] ?? 'No title',
            description: articleData['description'] ?? 'No description',
            url: articleData['url'] ?? '',
            imageUrl: articleData['urlToImage'],
            publishedAt: articleData['publishedAt'] ?? DateTime.now().toIso8601String(),
            source: articleData['source']['name'] ?? 'Unknown',
          ));
        }
        
        AppLogger.logSuccess('Parsed ${articles.length} search results for: ${event.query}');
        
        final hasMoreData = articles.length >= 20;
        emit(NewsLoadedState(
          articles,
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
        ));
        
        // Cache the search results
        await CacheService.instance.cacheNewsData(articles, page: _currentPage);
      } else {
        throw Exception('Failed to search news for: ${event.query}');
      }
    } catch (e) {
      AppLogger.logError('Failed to search news for "${event.query}": $e');
      
      // Fallback to mock search results
      AppLogger.logWarning('Using mock search results for: ${event.query}');
      final articles = _getMockSearchResults(event.query);
      emit(NewsLoadedState(
        articles,
        hasMoreData: true,
        currentPage: 1,
      ));
    }
  }
  
  Future<void> _onRefreshNews(
    RefreshNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Refreshing news data...');
    
    // Clear cache and reset pagination
    await CacheService.instance.clearNewsCache();
    _currentPage = 1;
    
    // Refresh based on current state - search query takes priority
    if (_currentSearchQuery != null) {
      AppLogger.logInfo('Refreshing search results for: $_currentSearchQuery');
      add(SearchNewsEvent(_currentSearchQuery!));
    } else {
      AppLogger.logInfo('Refreshing category news for: $_currentCategory');
      if (_currentCategory == 'general') {
        add(GetTopHeadlinesEvent());
      } else {
        add(GetNewsByCategoryEvent(_currentCategory));
      }
    }
  }
  
  Future<void> _onLoadMoreNews(
    LoadMoreNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NewsLoadedState) return;
    if (currentState.isSavedArticlesView) return; // No pagination for saved articles
    if (!currentState.hasMoreData) return;
    
    AppLogger.logBloc('Loading more news data...');
    emit(NewsLoadingMoreState(currentState.articles));
    
    _currentPage = currentState.currentPage + 1;
    
    try {
      AppLogger.logNews('Attempting to fetch more news (page $_currentPage)...');
      
      // Load more based on current context
      dynamic response;
      if (_currentSearchQuery != null) {
        response = await NetworkClient.instance.searchNews(
          query: _currentSearchQuery!,
          page: _currentPage,
        );
      } else {
        response = await NetworkClient.instance.getTopHeadlines(
          category: _currentCategory,
          page: _currentPage,
        );
      }
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('More news received successfully');
        
        final newArticles = <NewsArticle>[];
        final articlesData = data['articles'] as List;
        
        for (final articleData in articlesData) {
          newArticles.add(NewsArticle(
            title: articleData['title'] ?? 'No title',
            description: articleData['description'] ?? 'No description',
            url: articleData['url'] ?? '',
            imageUrl: articleData['urlToImage'],
            publishedAt: articleData['publishedAt'] ?? DateTime.now().toIso8601String(),
            source: articleData['source']['name'] ?? 'Unknown',
          ));
        }
        
        final allArticles = [...currentState.articles, ...newArticles];
        final hasMoreData = newArticles.length >= 20;
        
        emit(NewsLoadedState(
          allArticles,
          hasMoreData: hasMoreData,
          currentPage: _currentPage,
        ));
        
        // Cache the additional news data
        await CacheService.instance.cacheNewsData(newArticles, page: _currentPage);
        
        AppLogger.logSuccess('Loaded ${newArticles.length} more articles');
      } else {
        throw Exception('Failed to load more news');
      }
    } catch (e) {
      AppLogger.logError('Failed to load more news: $e');
      
      // Fallback to showing current articles with no more data
      emit(NewsLoadedState(
        currentState.articles,
        hasMoreData: false,
        currentPage: currentState.currentPage,
      ));
    }
  }
  
  Future<void> _onLoadCachedNews(
    LoadCachedNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Loading cached news data...');
    
    final cachedArticles = CacheService.instance.getCachedNewsData();
    if (cachedArticles.isNotEmpty) {
      AppLogger.logSuccess('Cached news data loaded');
      final cachedPage = CacheService.instance.getCurrentNewsPage();
      emit(NewsLoadedState(
        cachedArticles,
        hasMoreData: true,
        currentPage: cachedPage,
      ));
    } else {
      AppLogger.logWarning('No cached news data available');
      add(GetTopHeadlinesEvent());
    }
  }
  
  Future<void> _onTestNewsApi(
    TestNewsApiEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Testing News API...');
    emit(NewsLoadingState());
    
    try {
      await NetworkClient.instance.testApiKeys();
      AppLogger.logSuccess('News API test completed');
      add(GetTopHeadlinesEvent());
    } catch (e) {
      AppLogger.logError('News API test failed: $e');
      emit(NewsErrorState('News API test failed: $e'));
    }
  }
  
  Future<void> _onSaveArticle(
    SaveArticleEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Saving article: ${event.article.title}');
    
    try {
      final success = await SavedNewsService.instance.saveArticle(event.article);
      if (success) {
        AppLogger.logSuccess('Article saved successfully');
        
        // Force a rebuild by emitting a new state with timestamp
        final currentState = state;
        if (currentState is NewsLoadedState) {
          emit(NewsLoadedState(
            currentState.articles,
            isSavedArticlesView: currentState.isSavedArticlesView,
          ));
        }
      } else {
        AppLogger.logError('Failed to save article');
        emit(NewsErrorState('Failed to save article'));
      }
    } catch (e) {
      AppLogger.logError('Error saving article: $e');
      emit(NewsErrorState('Error saving article: $e'));
    }
  }
  
  Future<void> _onRemoveSavedArticle(
    RemoveSavedArticleEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Removing saved article: ${event.articleUrl}');
    
    try {
      final success = await SavedNewsService.instance.removeSavedArticle(event.articleUrl);
      if (success) {
        AppLogger.logSuccess('Article removed from saved');
        
        // If currently viewing saved articles, refresh the list
        final currentState = state;
        if (currentState is NewsLoadedState && currentState.isSavedArticlesView) {
          add(GetSavedArticlesEvent());
        } else if (currentState is NewsLoadedState) {
          // Force a rebuild by emitting a new state with timestamp
          emit(NewsLoadedState(
            currentState.articles,
            isSavedArticlesView: currentState.isSavedArticlesView,
          ));
        }
      } else {
        AppLogger.logError('Failed to remove saved article');
        emit(NewsErrorState('Failed to remove article'));
      }
    } catch (e) {
      AppLogger.logError('Error removing saved article: $e');
      emit(NewsErrorState('Error removing article: $e'));
    }
  }
  
  Future<void> _onGetSavedArticles(
    GetSavedArticlesEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Getting saved articles...');
    emit(NewsLoadingState());
    
    try {
      final savedArticles = SavedNewsService.instance.getSavedArticles();
      AppLogger.logSuccess('Retrieved ${savedArticles.length} saved articles');
      emit(NewsLoadedState(savedArticles, isSavedArticlesView: true));
    } catch (e) {
      AppLogger.logError('Error getting saved articles: $e');
      emit(NewsErrorState('Error loading saved articles: $e'));
    }
  }
  
  /// Check if an article is saved
  bool isArticleSaved(String articleUrl) {
    return SavedNewsService.instance.isArticleSaved(articleUrl);
  }
  
  /// Get saved articles count
  int getSavedArticlesCount() {
    return SavedNewsService.instance.getSavedArticlesCount();
  }
  
  List<NewsArticle> _getMockArticles() {
    return [
      const NewsArticle(
        title: 'Breaking: Major Tech Announcement',
        description: 'A major tech company announces groundbreaking innovation.',
        url: 'https://example.com/news1',
        imageUrl: 'https://via.placeholder.com/300x200',
        publishedAt: '2025-01-01T12:00:00Z',
        source: 'Tech News',
      ),
      const NewsArticle(
        title: 'Weather Update: Clear Skies Ahead',
        description: 'Meteorologists predict sunny weather for the weekend.',
        url: 'https://example.com/news2',
        imageUrl: 'https://via.placeholder.com/300x200',
        publishedAt: '2025-01-01T11:00:00Z',
        source: 'Weather Channel',
      ),
      const NewsArticle(
        title: 'Sports: Championship Finals',
        description: 'The championship finals are set to begin next week.',
        url: 'https://example.com/news3',
        imageUrl: 'https://via.placeholder.com/300x200',
        publishedAt: '2025-01-01T10:00:00Z',
        source: 'Sports Network',
      ),
    ];
  }
  
  List<NewsArticle> _getMockArticlesForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return [
          const NewsArticle(
            title: 'AI Revolution: New Breakthrough Announced',
            description: 'Scientists unveil revolutionary AI technology that could change the world.',
            url: 'https://example.com/tech1',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T15:00:00Z',
            source: 'TechCrunch',
          ),
          const NewsArticle(
            title: 'Smartphone Innovation: Foldable Display Tech',
            description: 'New foldable display technology promises better durability and performance.',
            url: 'https://example.com/tech2',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T14:00:00Z',
            source: 'The Verge',
          ),
        ];
      case 'sports':
        return [
          const NewsArticle(
            title: 'World Cup Qualifiers: Exciting Matches Ahead',
            description: 'Teams prepare for crucial World Cup qualifying matches this weekend.',
            url: 'https://example.com/sports1',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T13:00:00Z',
            source: 'ESPN',
          ),
          const NewsArticle(
            title: 'Olympic Training: Athletes Gear Up',
            description: 'Olympic athletes intensify training as games approach.',
            url: 'https://example.com/sports2',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T12:30:00Z',
            source: 'Sports Illustrated',
          ),
        ];
      case 'business':
        return [
          const NewsArticle(
            title: 'Stock Market Surge: Tech Stocks Lead',
            description: 'Technology stocks continue to drive market growth in early trading.',
            url: 'https://example.com/business1',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T09:00:00Z',
            source: 'Wall Street Journal',
          ),
          const NewsArticle(
            title: 'Cryptocurrency Update: Bitcoin Reaches New High',
            description: 'Bitcoin and other cryptocurrencies see significant gains this week.',
            url: 'https://example.com/business2',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T08:30:00Z',
            source: 'Financial Times',
          ),
        ];
      case 'health':
        return [
          const NewsArticle(
            title: 'Medical Breakthrough: New Treatment Discovered',
            description: 'Researchers discover promising new treatment for common condition.',
            url: 'https://example.com/health1',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T16:00:00Z',
            source: 'Medical News',
          ),
          const NewsArticle(
            title: 'Wellness Trend: Mental Health Awareness',
            description: 'Growing awareness about mental health leads to new support programs.',
            url: 'https://example.com/health2',
            imageUrl: 'https://via.placeholder.com/300x200',
            publishedAt: '2025-01-01T15:30:00Z',
            source: 'Health Magazine',
          ),
        ];
      default:
        return _getMockArticles(); // Return general articles for other categories
    }
  }
  
  List<NewsArticle> _getMockSearchResults(String query) {
    return [
      NewsArticle(
        title: 'Search Result: $query in Headlines',
        description: 'This is a mock search result for the query "$query". Real search results would be more relevant.',
        url: 'https://example.com/search1',
        imageUrl: 'https://via.placeholder.com/300x200',
        publishedAt: DateTime.now().toIso8601String(),
        source: 'Search Results',
      ),
      NewsArticle(
        title: 'Latest News About $query',
        description: 'Another mock search result showing content related to "$query". API would return actual matching articles.',
        url: 'https://example.com/search2',
        imageUrl: 'https://via.placeholder.com/300x200',
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        source: 'News Search',
      ),
    ];
  }
}