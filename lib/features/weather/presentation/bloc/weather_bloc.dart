import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/error/error_handler.dart';

// Events
abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  
  @override
  List<Object> get props => [];
}

class GetCurrentWeatherEvent extends WeatherEvent {}

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
    add(GetCurrentWeatherEvent());
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