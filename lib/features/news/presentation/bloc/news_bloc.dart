import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class NewsEvent extends Equatable {
  const NewsEvent();
  
  @override
  List<Object> get props => [];
}

class GetTopHeadlinesEvent extends NewsEvent {}

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
  NewsBloc() : super(NewsInitialState()) {
    on<GetTopHeadlinesEvent>(_onGetTopHeadlines);
    on<GetNewsByCategoryEvent>(_onGetNewsByCategory);
    on<SearchNewsEvent>(_onSearchNews);
    on<RefreshNewsEvent>(_onRefreshNews);
  }
  
  Future<void> _onGetTopHeadlines(
    GetTopHeadlinesEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoadingState());
    
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      final articles = _getMockArticles();
      emit(NewsLoadedState(articles));
    } catch (e) {
      emit(NewsErrorState(e.toString()));
    }
  }
  
  Future<void> _onGetNewsByCategory(
    GetNewsByCategoryEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoadingState());
    
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      final articles = _getMockArticles();
      emit(NewsLoadedState(articles));
    } catch (e) {
      emit(NewsErrorState(e.toString()));
    }
  }
  
  Future<void> _onSearchNews(
    SearchNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoadingState());
    
    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      final articles = _getMockArticles();
      emit(NewsLoadedState(articles));
    } catch (e) {
      emit(NewsErrorState(e.toString()));
    }
  }
  
  Future<void> _onRefreshNews(
    RefreshNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    add(GetTopHeadlinesEvent());
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
}