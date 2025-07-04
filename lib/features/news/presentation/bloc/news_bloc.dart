import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';

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

class RefreshNewsEvent extends NewsEvent {}

// States
abstract class NewsState extends Equatable {
  const NewsState();
  
  @override
  List<Object> get props => [];
}

class NewsInitialState extends NewsState {}

class NewsLoadingState extends NewsState {}

class NewsLoadedState extends NewsState {
  final List<NewsArticle> articles;
  
  const NewsLoadedState(this.articles);
  
  @override
  List<Object> get props => [articles];
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
  
  NewsBloc() : super(NewsInitialState()) {
    on<GetTopHeadlinesEvent>(_onGetTopHeadlines);
    on<GetNewsByCategoryEvent>(_onGetNewsByCategory);
    on<SearchNewsEvent>(_onSearchNews);
    on<RefreshNewsEvent>(_onRefreshNews);
    on<TestNewsApiEvent>(_onTestNewsApi);
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
    
    try {
      AppLogger.logNews('Attempting to fetch top headlines...');
      
      // Test with real API call
      final response = await NetworkClient.instance.getTopHeadlines(
        category: _currentCategory,
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
        emit(NewsLoadedState(articles));
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      AppLogger.logError('Failed to get top headlines: $e');
      
      // Fallback to mock data for UI testing
      AppLogger.logWarning('Using mock data for UI testing');
      final articles = _getMockArticles();
      emit(NewsLoadedState(articles));
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
    
    try {
      AppLogger.logNews('Attempting to fetch news for category: ${event.category}');
      
      // Use real API call for category news
      final response = await NetworkClient.instance.getTopHeadlines(
        category: event.category,
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
        emit(NewsLoadedState(articles));
      } else {
        throw Exception('Failed to load news for category: ${event.category}');
      }
    } catch (e) {
      AppLogger.logError('Failed to get news for category ${event.category}: $e');
      
      // Fallback to mock data with category context
      AppLogger.logWarning('Using mock data for category: ${event.category}');
      final articles = _getMockArticlesForCategory(event.category);
      emit(NewsLoadedState(articles));
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
    
    try {
      AppLogger.logNews('Attempting to search news for: ${event.query}');
      
      // Use real API call for search
      final response = await NetworkClient.instance.searchNews(
        query: event.query,
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
        emit(NewsLoadedState(articles));
      } else {
        throw Exception('Failed to search news for: ${event.query}');
      }
    } catch (e) {
      AppLogger.logError('Failed to search news for "${event.query}": $e');
      
      // Fallback to mock search results
      AppLogger.logWarning('Using mock search results for: ${event.query}');
      final articles = _getMockSearchResults(event.query);
      emit(NewsLoadedState(articles));
    }
  }
  
  Future<void> _onRefreshNews(
    RefreshNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    AppLogger.logBloc('Refreshing news data...');
    
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