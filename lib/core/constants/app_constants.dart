import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API URLs
  static const String weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  
  // API Keys - Read from environment file
  static String get weatherApiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
  static String get newsApiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  // Cache Keys
  static const String weatherCacheKey = 'weather_cache';
  static const String newsCacheKey = 'news_cache';
  static const String lastUpdateKey = 'last_update';

  // Settings
  static const String selectedCitiesKey = 'selected_cities';
  static const String themeKey = 'theme_mode';
  static const String temperatureUnitKey = 'temperature_unit';
  
  // Default Values
  static const String defaultCity = 'London';
  static const int cacheTimeoutMinutes = 10;
  static const int maxNewsArticles = 50;
  static const int maxCities = 5;
  
  // News Categories
  static const List<String> newsCategories = [
    'general',
    'business',
    'technology',
    'sports',
    'entertainment',
    'health',
    'science',
  ];
  
  // Weather Update Intervals
  static const Duration weatherUpdateInterval = Duration(minutes: 15);
  static const Duration newsUpdateInterval = Duration(minutes: 30);
  
  // Helper method to validate API keys
  static bool get areApiKeysValid {
    return weatherApiKey.isNotEmpty && newsApiKey.isNotEmpty;
  }
}
