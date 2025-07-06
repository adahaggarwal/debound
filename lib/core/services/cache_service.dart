import 'package:hive/hive.dart';
import '../utils/app_logger.dart';
import '../../features/weather/presentation/bloc/weather_bloc.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';

class CacheService {
  static CacheService? _instance;
  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }
  
  CacheService._();
  
  Box<Map>? _weatherBox;
  Box<Map>? _newsBox;
  Box<String>? _metadataBox; // For storing strings like timestamps and page numbers
  
  static const String _weatherBoxName = 'weather_cache';
  static const String _newsBoxName = 'news_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const String _lastWeatherUpdateKey = 'last_weather_update';
  static const String _weatherDataKey = 'weather_data';
  static const String _lastNewsUpdateKey = 'last_news_update';
  static const String _newsDataKey = 'news_data';
  static const String _newsPaginationKey = 'news_pagination';
  
  /// Initialize cache service
  Future<void> initialize() async {
    try {
      _weatherBox = await Hive.openBox<Map>(_weatherBoxName);
      _newsBox = await Hive.openBox<Map>(_newsBoxName);
      _metadataBox = await Hive.openBox<String>(_metadataBoxName);
      AppLogger.logSuccess('CacheService initialized');
    } catch (e) {
      AppLogger.logError('Failed to initialize CacheService: $e');
    }
  }
  
  // WEATHER CACHING
  
  /// Cache weather data
  Future<void> cacheWeatherData(WeatherLoadedState weatherState) async {
    try {
      if (_weatherBox == null) await initialize();
      
      final weatherData = {
        'city': weatherState.city,
        'temperature': weatherState.temperature,
        'condition': weatherState.condition,
        'description': weatherState.description,
        'humidity': weatherState.humidity,
        'pressure': weatherState.pressure,
        'visibility': weatherState.visibility,
        'windSpeed': weatherState.windSpeed,
        'currentLatitude': weatherState.currentLatitude,
        'currentLongitude': weatherState.currentLongitude,
        'forecast': weatherState.forecast?.map((f) => {
          'date': f.date.toIso8601String(),
          'maxTemp': f.maxTemp,
          'minTemp': f.minTemp,
          'condition': f.condition,
          'description': f.description,
          'icon': f.icon,
        }).toList(),
        'otherCities': weatherState.otherCities.map((city) => {
          'cityName': city.cityName,
          'temperature': city.temperature,
          'condition': city.condition,
          'description': city.description,
          'latitude': city.latitude,
          'longitude': city.longitude,
          'isNearby': city.isNearby,
        }).toList(),
      };
      
      await _weatherBox!.put(_weatherDataKey, weatherData);
      await _metadataBox!.put(_lastWeatherUpdateKey, DateTime.now().toIso8601String());
      
      AppLogger.logSuccess('Weather data cached');
    } catch (e) {
      AppLogger.logError('Failed to cache weather data: $e');
    }
  }
  
  /// Get cached weather data
  WeatherLoadedState? getCachedWeatherData() {
    try {
      if (_weatherBox == null) return null;
      
      final weatherData = _weatherBox!.get(_weatherDataKey);
      if (weatherData == null) return null;
      
      // Parse forecast data
      List<ForecastDay>? forecast;
      if (weatherData['forecast'] != null) {
        final forecastList = weatherData['forecast'] as List;
        forecast = forecastList.map((f) => ForecastDay(
          date: DateTime.parse(f['date']),
          maxTemp: (f['maxTemp'] as num).toDouble(),
          minTemp: (f['minTemp'] as num).toDouble(),
          condition: f['condition'] ?? '',
          description: f['description'] ?? '',
          icon: f['icon'] ?? '',
        )).toList();
      }
      
      // Parse other cities data
      List<CityWeather> otherCities = [];
      if (weatherData['otherCities'] != null) {
        final citiesList = weatherData['otherCities'] as List;
        otherCities = citiesList.map((city) => CityWeather(
          cityName: city['cityName'] ?? '',
          temperature: (city['temperature'] as num).toDouble(),
          condition: city['condition'] ?? '',
          description: city['description'] ?? '',
          latitude: (city['latitude'] as num).toDouble(),
          longitude: (city['longitude'] as num).toDouble(),
          isNearby: city['isNearby'] ?? false,
        )).toList();
      }
      
      return WeatherLoadedState(
        city: weatherData['city'] ?? '',
        temperature: (weatherData['temperature'] as num?)?.toDouble() ?? 0.0,
        condition: weatherData['condition'] ?? '',
        description: weatherData['description'] ?? '',
        humidity: (weatherData['humidity'] as num?)?.toDouble(),
        pressure: (weatherData['pressure'] as num?)?.toDouble(),
        visibility: (weatherData['visibility'] as num?)?.toDouble(),
        windSpeed: (weatherData['windSpeed'] as num?)?.toDouble(),
        forecast: forecast,
        otherCities: otherCities,
        currentLatitude: (weatherData['currentLatitude'] as num?)?.toDouble(),
        currentLongitude: (weatherData['currentLongitude'] as num?)?.toDouble(),
      );
    } catch (e) {
      AppLogger.logError('Failed to get cached weather data: $e');
      return null;
    }
  }
  
  /// Check if weather data is available offline
  bool hasWeatherCache() {
    if (_weatherBox == null) return false;
    return _weatherBox!.containsKey(_weatherDataKey);
  }
  
  // NEWS CACHING
  
  /// Cache news data
  Future<void> cacheNewsData(List<NewsArticle> articles, {int page = 1}) async {
    try {
      if (_newsBox == null) await initialize();
      
      final newsData = {
        'articles': articles.map((article) => {
          'title': article.title,
          'description': article.description,
          'url': article.url,
          'imageUrl': article.imageUrl,
          'publishedAt': article.publishedAt,
          'source': article.source,
        }).toList(),
        'page': page,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      // If it's page 1, replace the cache. Otherwise, append to existing cache
      if (page == 1) {
        await _newsBox!.put(_newsDataKey, newsData);
      } else {
        final existingData = _newsBox!.get(_newsDataKey);
        if (existingData != null) {
          final existingArticles = existingData['articles'] as List;
          final newArticles = newsData['articles'] as List;
          
          final combinedData = {
            'articles': [...existingArticles, ...newArticles],
            'page': page,
            'lastUpdate': DateTime.now().toIso8601String(),
          };
          await _newsBox!.put(_newsDataKey, combinedData);
        } else {
          await _newsBox!.put(_newsDataKey, newsData);
        }
      }
      
      await _metadataBox!.put(_lastNewsUpdateKey, DateTime.now().toIso8601String());
      await _metadataBox!.put(_newsPaginationKey, page.toString());
      
      AppLogger.logSuccess('News data cached (page $page)');
    } catch (e) {
      AppLogger.logError('Failed to cache news data: $e');
    }
  }
  
  /// Get cached news data
  List<NewsArticle> getCachedNewsData() {
    try {
      if (_newsBox == null) return [];
      
      final newsData = _newsBox!.get(_newsDataKey);
      if (newsData == null) return [];
      
      final articlesList = newsData['articles'] as List;
      return articlesList.map((article) => NewsArticle(
        title: article['title'] ?? 'No title',
        description: article['description'] ?? 'No description',
        url: article['url'] ?? '',
        imageUrl: article['imageUrl'],
        publishedAt: article['publishedAt'] ?? DateTime.now().toIso8601String(),
        source: article['source'] ?? 'Unknown',
      )).toList();
    } catch (e) {
      AppLogger.logError('Failed to get cached news data: $e');
      return [];
    }
  }
  
  /// Check if news data is available offline
  bool hasNewsCache() {
    if (_newsBox == null) return false;
    return _newsBox!.containsKey(_newsDataKey);
  }
  
  /// Get current news page number
  int getCurrentNewsPage() {
    if (_metadataBox == null) return 1;
    final pageString = _metadataBox!.get(_newsPaginationKey);
    return pageString != null ? int.tryParse(pageString) ?? 1 : 1;
  }
  
  /// Clear news cache (useful for refresh)
  Future<void> clearNewsCache() async {
    try {
      if (_newsBox == null || _metadataBox == null) await initialize();
      await _newsBox!.delete(_newsDataKey);
      await _metadataBox!.delete(_newsPaginationKey);
      AppLogger.logInfo('News cache cleared');
    } catch (e) {
      AppLogger.logError('Failed to clear news cache: $e');
    }
  }
  
  /// Clear weather cache
  Future<void> clearWeatherCache() async {
    try {
      if (_weatherBox == null) await initialize();
      await _weatherBox!.delete(_weatherDataKey);
      AppLogger.logInfo('Weather cache cleared');
    } catch (e) {
      AppLogger.logError('Failed to clear weather cache: $e');
    }
  }
  
  /// Get last update time for weather
  DateTime? getLastWeatherUpdate() {
    try {
      if (_metadataBox == null) return null;
      final lastUpdate = _metadataBox!.get(_lastWeatherUpdateKey);
      return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get last update time for news
  DateTime? getLastNewsUpdate() {
    try {
      if (_metadataBox == null) return null;
      final lastUpdate = _metadataBox!.get(_lastNewsUpdateKey);
      return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
    } catch (e) {
      return null;
    }
  }
}