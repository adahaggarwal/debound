import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class NetworkClient {
  static NetworkClient? _instance;
  late Dio _dio;
  
  NetworkClient._() {
    _dio = Dio();
    _setupInterceptors();
    _logApiKeys();
  }
  
  static NetworkClient get instance {
    _instance ??= NetworkClient._();
    return _instance!;
  }
  
  Dio get dio => _dio;

  void _logApiKeys() {
    AppLogger.logInfo('🔑 Checking API Keys Configuration...');
    
    // Check Weather API Key
    if (AppConstants.weatherApiKey == 'YOUR_WEATHER_API_KEY') {
      AppLogger.logWarning('Weather API Key is not configured! Please add your OpenWeatherMap API key.');
    } else {
      AppLogger.logApiKey('Weather', AppConstants.weatherApiKey);
      AppLogger.logSuccess('Weather API Key is configured');
    }
    
    // Check News API Key
    if (AppConstants.newsApiKey == 'YOUR_NEWS_API_KEY') {
      AppLogger.logWarning('News API Key is not configured! Please add your NewsAPI key.');
    } else {
      AppLogger.logApiKey('News', AppConstants.newsApiKey);
      AppLogger.logSuccess('News API Key is configured');
    }
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          AppLogger.logRequest(options.method, options.uri.toString(), options.queryParameters);
          
          // Check internet connectivity
          final connectivityResult = await Connectivity().checkConnectivity();
          AppLogger.logNetwork('Connectivity Status: $connectivityResult');
          
          if (connectivityResult == ConnectivityResult.none) {
            AppLogger.logError('No internet connection available');
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'No internet connection',
              ),
            );
            return;
          }
          
          // Add timeout
          options.connectTimeout = const Duration(seconds: 10);
          options.receiveTimeout = const Duration(seconds: 10);
          AppLogger.logNetwork('Request timeout set to 10 seconds');
          
          // Log headers
          if (options.headers.isNotEmpty) {
            AppLogger.logNetwork('Headers: ${options.headers.toString()}');
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.logResponse(
            response.requestOptions.uri.toString(),
            response.statusCode ?? 0,
            response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.logError('API Error: ${error.message}');
          AppLogger.logError('Error Type: ${error.type}');
          AppLogger.logError('Request URL: ${error.requestOptions.uri}');
          
          if (error.response != null) {
            AppLogger.logError('Response Status: ${error.response?.statusCode}');
            AppLogger.logError('Response Data: ${error.response?.data}');
          }
          
          handler.next(error);
        },
      ),
    );
  }
  
  // Weather API calls
  Future<Response> getWeatherData(String city) async {
    AppLogger.logWeather('Fetching weather data for city: $city');
    
    if (AppConstants.weatherApiKey == 'YOUR_WEATHER_API_KEY') {
      AppLogger.logError('Weather API Key not configured!');
      throw Exception('Weather API Key not configured');
    }
    
    final params = {
      'q': city,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
    };
    
    AppLogger.logWeather('Request params: ${params.toString()}');
    
    try {
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}/weather',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('Weather data fetched successfully for $city');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to fetch weather data for $city: $e');
      rethrow;
    }
  }
  
  Future<Response> getWeatherForecast(String city) async {
    AppLogger.logWeather('Fetching weather forecast for city: $city');
    
    if (AppConstants.weatherApiKey == 'YOUR_WEATHER_API_KEY') {
      AppLogger.logError('Weather API Key not configured!');
      throw Exception('Weather API Key not configured');
    }
    
    final params = {
      'q': city,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
    };
    
    try {
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}/forecast',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('Weather forecast fetched successfully for $city');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to fetch weather forecast for $city: $e');
      rethrow;
    }
  }
  
  Future<Response> getWeatherByCoordinates(double lat, double lon) async {
    AppLogger.logWeather('Fetching weather data for coordinates: lat=$lat, lon=$lon');
    
    if (AppConstants.weatherApiKey == 'YOUR_WEATHER_API_KEY') {
      AppLogger.logError('Weather API Key not configured!');
      throw Exception('Weather API Key not configured');
    }
    
    final params = {
      'lat': lat,
      'lon': lon,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
    };
    
    try {
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}/weather',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('Weather data fetched successfully for coordinates');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to fetch weather data for coordinates: $e');
      rethrow;
    }
  }
  
  Future<Response> getWeatherForecastByCoordinates(double lat, double lon) async {
    AppLogger.logWeather('Fetching weather forecast for coordinates: lat=$lat, lon=$lon');
    
    if (AppConstants.weatherApiKey == 'YOUR_WEATHER_API_KEY') {
      AppLogger.logError('Weather API Key not configured!');
      throw Exception('Weather API Key not configured');
    }
    
    final params = {
      'lat': lat,
      'lon': lon,
      'appid': AppConstants.weatherApiKey,
      'units': 'metric',
    };
    
    try {
      final response = await _dio.get(
        '${AppConstants.weatherApiBaseUrl}/forecast',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('Weather forecast fetched successfully for coordinates');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to fetch weather forecast for coordinates: $e');
      rethrow;
    }
  }
  
  // News API calls
  Future<Response> getTopHeadlines({
    String? category,
    String? country = 'us',
    int pageSize = 20,
    int page = 1,
  }) async {
    AppLogger.logNews('Fetching top headlines - category: $category, country: $country');
    
    if (AppConstants.newsApiKey == 'YOUR_NEWS_API_KEY') {
      AppLogger.logError('News API Key not configured!');
      throw Exception('News API Key not configured');
    }
    
    final params = {
      'apiKey': AppConstants.newsApiKey,
      'category': category,
      'country': country,
      'pageSize': pageSize,
      'page': page,
    };
    
    try {
      final response = await _dio.get(
        '${AppConstants.newsApiBaseUrl}/top-headlines',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('Top headlines fetched successfully');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to fetch top headlines: $e');
      rethrow;
    }
  }
  
  Future<Response> searchNews({
    required String query,
    String? sortBy = 'publishedAt',
    int pageSize = 20,
    int page = 1,
  }) async {
    AppLogger.logNews('Searching news for query: $query');
    
    if (AppConstants.newsApiKey == 'YOUR_NEWS_API_KEY') {
      AppLogger.logError('News API Key not configured!');
      throw Exception('News API Key not configured');
    }
    
    final params = {
      'apiKey': AppConstants.newsApiKey,
      'q': query,
      'sortBy': sortBy,
      'pageSize': pageSize,
      'page': page,
    };
    
    try {
      final response = await _dio.get(
        '${AppConstants.newsApiBaseUrl}/everything',
        queryParameters: params,
      );
      
      AppLogger.logSuccess('News search completed successfully');
      return response;
    } catch (e) {
      AppLogger.logError('Failed to search news: $e');
      rethrow;
    }
  }

  // Test API Keys
  Future<void> testApiKeys() async {
    AppLogger.logInfo('🧪 Testing API Keys...');
    
    // Test Weather API
    await _testWeatherApi();
    
    // Test News API
    await _testNewsApi();
  }

  Future<void> _testWeatherApi() async {
    try {
      AppLogger.logWeather('Testing Weather API...');
      final response = await getWeatherData('London');
      
      if (response.statusCode == 200) {
        AppLogger.logSuccess('Weather API Test: SUCCESS ✅');
        AppLogger.logWeather('Sample data: ${response.data['name']} - ${response.data['main']['temp']}°C');
      } else {
        AppLogger.logError('Weather API Test: FAILED ❌ - Status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.logError('Weather API Test: FAILED ❌ - Error: $e');
    }
  }

  Future<void> _testNewsApi() async {
    try {
      AppLogger.logNews('Testing News API...');
      final response = await getTopHeadlines(pageSize: 1);
      
      if (response.statusCode == 200) {
        AppLogger.logSuccess('News API Test: SUCCESS ✅');
        final articles = response.data['articles'] as List;
        if (articles.isNotEmpty) {
          AppLogger.logNews('Sample article: ${articles[0]['title']}');
        }
      } else {
        AppLogger.logError('News API Test: FAILED ❌ - Status: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.logError('News API Test: FAILED ❌ - Error: $e');
    }
  }
}