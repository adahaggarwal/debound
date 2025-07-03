import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/services/location_service.dart';

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
  
  const WeatherLoadedState({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.description,
  });
  
  @override
  List<Object> get props => [city, temperature, condition, description];
}

class WeatherErrorState extends WeatherState {
  final String message;
  
  const WeatherErrorState(this.message);
  
  @override
  List<Object> get props => [message];
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
        AppLogger.logWeather('Weather: ${data['name']} - ${data['main']['temp']}°C - ${data['weather'][0]['description']}');
        
        emit(WeatherLoadedState(
          city: data['name'] ?? 'London',
          temperature: (data['main']['temp'] ?? 22.5).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
        ));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      AppLogger.logError('Failed to get current weather: $e');
      
      // Fallback to mock data for UI testing
      AppLogger.logWarning('Using mock data for UI testing');
      emit(const WeatherLoadedState(
        city: 'London (Mock)',
        temperature: 22.5,
        condition: 'sunny',
        description: 'Clear sky (Mock Data)',
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
      // Get user's current location
      final locationData = await LocationService.instance.getCurrentLocationData();
      
      if (locationData == null) {
        AppLogger.logWarning('Could not get location, falling back to default city');
        add(GetCurrentWeatherEvent());
        return;
      }
      
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
        AppLogger.logWeather('Weather: ${data['name']} - ${data['main']['temp']}°C - ${data['weather'][0]['description']}');
        
        emit(WeatherLoadedState(
          city: '${event.cityName} 📍',
          temperature: (data['main']['temp'] ?? 22.5).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
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
          emit(WeatherLoadedState(
            city: '${event.cityName} 📍',
            temperature: (data['main']['temp'] ?? 22.5).toDouble(),
            condition: data['weather'][0]['main'] ?? 'Clear',
            description: data['weather'][0]['description'] ?? 'Clear sky',
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
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Weather forecast received successfully');
        
        emit(WeatherLoadedState(
          city: data['name'] ?? event.city,
          temperature: (data['main']['temp'] ?? 25.0).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
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
}