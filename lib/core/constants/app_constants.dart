class AppConstants {
  // API URLs
  static const String weatherApiBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  
  // API Keys - You'll need to get these
  static const String weatherApiKey = '94249974b989b2a2dcaeef8cdfd57548';
  static const String newsApiKey = 'b211a5d67b0d4d60a125470a7f544333';

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
}