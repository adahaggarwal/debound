import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/weather_model.dart';

// Events
abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  
  @override
  List<Object> get props => [];
}

class GetCurrentWeatherEvent extends WeatherEvent {}

class GetLocationWeatherEvent extends WeatherEvent {}

class GetWeatherByLocationEvent extends WeatherEvent {
  final double latitude;
  final double longitude;
  final String cityName;
  
  const GetWeatherByLocationEvent({
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });
  
  @override
  List<Object> get props => [latitude, longitude, cityName];
}

class TestApiKeysEvent extends WeatherEvent {}

class GetWeatherForecastEvent extends WeatherEvent {
  final String city;
  
  const GetWeatherForecastEvent(this.city);
  
  @override
  List<Object> get props => [city];
}

class RefreshWeatherEvent extends WeatherEvent {}

// States
abstract class WeatherState extends Equatable {
  const WeatherState();
  
  @override
  List<Object> get props => [];
}

class WeatherInitialState extends WeatherState {}

class WeatherLoadingState extends WeatherState {}

class WeatherLoadedState extends WeatherState {
  final String city;
  final double temperature;
  final String condition;
  final String description;
  final double? humidity;
  final double? pressure;
  final double? visibility;
  final double? windSpeed;
  final List<ForecastDay>? forecast;
  
  const WeatherLoadedState({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.description,
    this.humidity,
    this.pressure,
    this.visibility,
    this.windSpeed,
    this.forecast,
  });
  
  @override
  List<Object> get props => [
    city, 
    temperature, 
    condition, 
    description, 
    humidity ?? 0.0, 
    pressure ?? 0.0, 
    visibility ?? 0.0, 
    windSpeed ?? 0.0,
    forecast ?? [],
  ];
}

class WeatherErrorState extends WeatherState {
  final String message;
  
  const WeatherErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}

// Forecast data class
class ForecastDay extends Equatable {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String description;
  final String icon;
  
  const ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.description,
    required this.icon,
  });
  
  @override
  List<Object> get props => [date, maxTemp, minTemp, condition, description, icon];
}

// BLoC
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitialState()) {
    on<GetCurrentWeatherEvent>(_onGetCurrentWeather);
    on<GetLocationWeatherEvent>(_onGetLocationWeather);
    on<GetWeatherByLocationEvent>(_onGetWeatherByLocation);
    on<GetWeatherForecastEvent>(_onGetWeatherForecast);
    on<RefreshWeatherEvent>(_onRefreshWeather);
    on<TestApiKeysEvent>(_onTestApiKeys);
  }
  
  Future<void> _onGetCurrentWeather(
    GetCurrentWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Getting current weather...');
    emit(WeatherLoadingState());
    
    try {
      AppLogger.logWeather('Attempting to fetch weather data...');
      
      // Test with real API call
      final response = await NetworkClient.instance.getWeatherData('London');
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Weather data received successfully');
        AppLogger.logWeather('API Response: ${data.toString()}');
        AppLogger.logWeather('Weather: ${data['name']} - ${data['main']['temp']}°C - ${data['weather'][0]['description']}');
        
        // Also get forecast data
        List<ForecastDay>? forecastData;
        try {
          final forecastResponse = await NetworkClient.instance.getWeatherForecast('London');
          if (forecastResponse.statusCode == 200) {
            forecastData = _parseForecastData(forecastResponse.data);
            AppLogger.logSuccess('Forecast data received successfully');
            AppLogger.logWeather('Forecast Response: ${forecastResponse.data.toString()}');
          }
        } catch (e) {
          AppLogger.logWarning('Could not fetch forecast data: $e');
        }
        
        emit(WeatherLoadedState(
          city: data['name'] ?? 'London',
          temperature: (data['main']['temp'] ?? 22.5).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
          humidity: (data['main']['humidity'] ?? 65).toDouble(),
          pressure: (data['main']['pressure'] ?? 1013).toDouble(),
          visibility: (data['visibility'] ?? 10000).toDouble() / 1000, // Convert to km
          windSpeed: (data['wind']?['speed'] ?? 5.2).toDouble(),
          forecast: forecastData,
        ));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      AppLogger.logError('Failed to get current weather: $e');
      
      // Fallback to mock data for UI testing
      AppLogger.logWarning('Using mock data for UI testing');
      emit(WeatherLoadedState(
        city: 'London (Mock)',
        temperature: 22.5,
        condition: 'sunny',
        description: 'Clear sky (Mock Data)',
        humidity: 65.0,
        pressure: 1013.0,
        visibility: 10.0,
        windSpeed: 5.2,
        forecast: _getMockForecastData(),
      ));
    }
  }
  
  Future<void> _onGetLocationWeather(
    GetLocationWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Getting location-based weather...');
    emit(WeatherLoadingState());
    
    try {
      // Check if location services are enabled first
      final isLocationServiceEnabled = await LocationService.instance.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        AppLogger.logError('Location services are disabled on device');
        emit(WeatherErrorState('Location services are disabled. Please enable location services in your device settings.'));
        return;
      }
      
      // Check current permission status
      final hasPermission = await LocationService.instance.isLocationPermissionGranted();
      AppLogger.logInfo('Current location permission status: $hasPermission');
      
      // Get user's actual location with permission request
      final locationData = await LocationService.instance.getCurrentLocationWithPermission();
      
      if (locationData == null) {
        AppLogger.logWarning('Could not get location, falling back to default city');
        emit(WeatherErrorState('Could not get your location. Please check location permissions and try again.'));
        return;
      }
      
      AppLogger.logSuccess('Location obtained: ${locationData.toString()}');
      
      // Get weather for user's location
      add(GetWeatherByLocationEvent(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        cityName: locationData.cityName,
      ));
    } catch (e) {
      AppLogger.logError('Failed to get location weather: $e');
      emit(WeatherErrorState('Failed to get location: $e'));
    }
  }
  
  Future<void> _onGetWeatherByLocation(
    GetWeatherByLocationEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Getting weather for ${event.cityName}...');
    emit(WeatherLoadingState());
    
    try {
      AppLogger.logWeather('Fetching weather for coordinates: ${event.latitude}, ${event.longitude}');
      
      final response = await NetworkClient.instance.getWeatherByCoordinates(
        event.latitude, 
        event.longitude,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Location weather data received successfully');
        AppLogger.logWeather('API Response: ${data.toString()}');
        AppLogger.logWeather('Weather: ${data['name']} - ${data['main']['temp']}°C - ${data['weather'][0]['description']}');
        
        // Also get forecast data for the location
        List<ForecastDay>? forecastData;
        try {
          final forecastResponse = await NetworkClient.instance.getWeatherForecastByCoordinates(
            event.latitude, 
            event.longitude,
          );
          if (forecastResponse.statusCode == 200) {
            forecastData = _parseForecastData(forecastResponse.data);
            AppLogger.logSuccess('Location forecast data received successfully');
            AppLogger.logWeather('Forecast Response: ${forecastResponse.data.toString()}');
          }
        } catch (e) {
          AppLogger.logWarning('Could not fetch forecast data for location: $e');
        }
        
        emit(WeatherLoadedState(
          city: '${event.cityName} 📍',
          temperature: (data['main']['temp'] ?? 22.5).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
          humidity: (data['main']['humidity'] ?? 65).toDouble(),
          pressure: (data['main']['pressure'] ?? 1013).toDouble(),
          visibility: (data['visibility'] ?? 10000).toDouble() / 1000, // Convert to km
          windSpeed: (data['wind']?['speed'] ?? 5.2).toDouble(),
          forecast: forecastData,
        ));
      } else {
        throw Exception('Failed to load weather data for location');
      }
    } catch (e) {
      AppLogger.logError('Failed to get weather by location: $e');
      
      // Fallback to city name weather
      AppLogger.logWarning('Trying to get weather by city name: ${event.cityName}');
      try {
        final response = await NetworkClient.instance.getWeatherData(event.cityName);
        
        if (response.statusCode == 200) {
          final data = response.data;
          AppLogger.logWeather('API Response: ${data.toString()}');
          
          // Also try to get forecast data
          List<ForecastDay>? forecastData;
          try {
            final forecastResponse = await NetworkClient.instance.getWeatherForecast(event.cityName);
            if (forecastResponse.statusCode == 200) {
              forecastData = _parseForecastData(forecastResponse.data);
              AppLogger.logWeather('Forecast Response: ${forecastResponse.data.toString()}');
            }
          } catch (e) {
            AppLogger.logWarning('Could not fetch forecast data: $e');
          }
          
          emit(WeatherLoadedState(
            city: '${event.cityName} 📍',
            temperature: (data['main']['temp'] ?? 22.5).toDouble(),
            condition: data['weather'][0]['main'] ?? 'Clear',
            description: data['weather'][0]['description'] ?? 'Clear sky',
            humidity: (data['main']['humidity'] ?? 65).toDouble(),
            pressure: (data['main']['pressure'] ?? 1013).toDouble(),
            visibility: (data['visibility'] ?? 10000).toDouble() / 1000,
            windSpeed: (data['wind']?['speed'] ?? 5.2).toDouble(),
            forecast: forecastData,
          ));
        } else {
          throw Exception('Failed to load weather data');
        }
      } catch (e2) {
        AppLogger.logError('Fallback weather request also failed: $e2');
        emit(WeatherErrorState('Could not get weather for your location'));
      }
    }
  }
  
  Future<void> _onGetWeatherForecast(
    GetWeatherForecastEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Getting weather forecast for ${event.city}...');
    emit(WeatherLoadingState());
    
    try {
      final response = await NetworkClient.instance.getWeatherData(event.city);
      final forecastResponse = await NetworkClient.instance.getWeatherForecast(event.city);
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Weather forecast received successfully');
        AppLogger.logWeather('API Response: ${data.toString()}');
        AppLogger.logWeather('Forecast Response: ${forecastResponse.data.toString()}');
        
        List<ForecastDay>? forecastData;
        if (forecastResponse.statusCode == 200) {
          forecastData = _parseForecastData(forecastResponse.data);
        }
        
        emit(WeatherLoadedState(
          city: data['name'] ?? event.city,
          temperature: (data['main']['temp'] ?? 25.0).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
          humidity: (data['main']['humidity'] ?? 65).toDouble(),
          pressure: (data['main']['pressure'] ?? 1013).toDouble(),
          visibility: (data['visibility'] ?? 10000).toDouble() / 1000,
          windSpeed: (data['wind']?['speed'] ?? 5.2).toDouble(),
          forecast: forecastData,
        ));
      } else {
        throw Exception('Failed to load weather forecast');
      }
    } catch (e) {
      AppLogger.logError('Failed to get weather forecast: $e');
      emit(WeatherErrorState(e.toString()));
    }
  }
  
  Future<void> _onRefreshWeather(
    RefreshWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Refreshing weather data...');
    add(GetLocationWeatherEvent());
  }
  
  Future<void> _onTestApiKeys(
    TestApiKeysEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Testing API keys...');
    emit(WeatherLoadingState());
    
    try {
      await NetworkClient.instance.testApiKeys();
      AppLogger.logSuccess('API keys test completed');
      add(GetCurrentWeatherEvent());
    } catch (e) {
      AppLogger.logError('API keys test failed: $e');
      emit(WeatherErrorState('API keys test failed: $e'));
    }
  }
  
  List<ForecastDay> _parseForecastData(Map<String, dynamic> data) {
    final List<dynamic> list = data['list'] ?? [];
    final List<ForecastDay> forecasts = [];
    
    // Group forecasts by day (OpenWeatherMap returns 3-hour intervals)
    final Map<String, List<Map<String, dynamic>>> dailyForecasts = {};
    
    for (final item in list) {
      final timestamp = item['dt'] * 1000;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!dailyForecasts.containsKey(dayKey)) {
        dailyForecasts[dayKey] = [];
      }
      dailyForecasts[dayKey]!.add(item);
    }
    
    // Get one forecast per day (take the one closest to noon)
    for (final entry in dailyForecasts.entries) {
      if (forecasts.length >= 5) break; // Only take 5 days
      
      final dayForecasts = entry.value;
      
      // Find the forecast closest to noon (12:00)
      Map<String, dynamic>? noonForecast;
      int closestToNoon = 24;
      
      for (final forecast in dayForecasts) {
        final timestamp = forecast['dt'] * 1000;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final hourDiff = (date.hour - 12).abs();
        
        if (hourDiff < closestToNoon) {
          closestToNoon = hourDiff;
          noonForecast = forecast;
        }
      }
      
      if (noonForecast != null) {
        // Calculate min and max temperatures for the day
        double minTemp = dayForecasts.first['main']['temp'].toDouble();
        double maxTemp = dayForecasts.first['main']['temp'].toDouble();
        
        for (final forecast in dayForecasts) {
          final temp = forecast['main']['temp'].toDouble();
          if (temp < minTemp) minTemp = temp;
          if (temp > maxTemp) maxTemp = temp;
        }
        
        final timestamp = noonForecast['dt'] * 1000;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        forecasts.add(ForecastDay(
          date: date,
          maxTemp: maxTemp,
          minTemp: minTemp,
          condition: noonForecast['weather'][0]['main'] ?? 'Clear',
          description: noonForecast['weather'][0]['description'] ?? 'Clear sky',
          icon: noonForecast['weather'][0]['icon'] ?? '01d',
        ));
      }
    }
    
    return forecasts;
  }
  
  List<ForecastDay> _getMockForecastData() {
    final now = DateTime.now();
    return [
      ForecastDay(
        date: now.add(const Duration(days: 1)),
        maxTemp: 22,
        minTemp: 17,
        condition: 'Clear',
        description: 'Sunny',
        icon: '01d',
      ),
      ForecastDay(
        date: now.add(const Duration(days: 2)),
        maxTemp: 19,
        minTemp: 14,
        condition: 'Clouds',
        description: 'Partly cloudy',
        icon: '02d',
      ),
      ForecastDay(
        date: now.add(const Duration(days: 3)),
        maxTemp: 16,
        minTemp: 11,
        condition: 'Rain',
        description: 'Light rain',
        icon: '10d',
      ),
      ForecastDay(
        date: now.add(const Duration(days: 4)),
        maxTemp: 24,
        minTemp: 19,
        condition: 'Clear',
        description: 'Sunny',
        icon: '01d',
      ),
      ForecastDay(
        date: now.add(const Duration(days: 5)),
        maxTemp: 20,
        minTemp: 15,
        condition: 'Clouds',
        description: 'Overcast',
        icon: '04d',
      ),
    ];
  }
}
