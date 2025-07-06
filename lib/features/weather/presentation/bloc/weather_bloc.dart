import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/cache_service.dart';

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

class AddCityEvent extends WeatherEvent {
  final String cityName;
  
  const AddCityEvent(this.cityName);
  
  @override
  List<Object> get props => [cityName];
}

class RemoveCityEvent extends WeatherEvent {
  final String cityName;
  
  const RemoveCityEvent(this.cityName);
  
  @override
  List<Object> get props => [cityName];
}

class LoadNearbyCitiesEvent extends WeatherEvent {
  final double latitude;
  final double longitude;
  
  const LoadNearbyCitiesEvent(this.latitude, this.longitude);
  
  @override
  List<Object> get props => [latitude, longitude];
}

class RefreshWeatherEvent extends WeatherEvent {}

class LoadCachedWeatherEvent extends WeatherEvent {}

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
  final List<CityWeather> otherCities;
  final double? currentLatitude;
  final double? currentLongitude;
  
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
    this.otherCities = const [],
    this.currentLatitude,
    this.currentLongitude,
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
    otherCities,
    currentLatitude ?? 0.0,
    currentLongitude ?? 0.0,
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

// City weather data class
class CityWeather extends Equatable {
  final String cityName;
  final double temperature;
  final String condition;
  final String description;
  final double latitude;
  final double longitude;
  final bool isNearby;
  
  const CityWeather({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isNearby = false,
  });
  
  @override
  List<Object> get props => [cityName, temperature, condition, description, latitude, longitude, isNearby];
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
    on<AddCityEvent>(_onAddCity);
    on<RemoveCityEvent>(_onRemoveCity);
    on<LoadNearbyCitiesEvent>(_onLoadNearbyCities);
    on<LoadCachedWeatherEvent>(_onLoadCachedWeather);
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
          currentLatitude: (data['coord']['lat'] ?? 51.5074).toDouble(),
          currentLongitude: (data['coord']['lon'] ?? -0.1278).toDouble(),
        ));
        
        // Cache the weather data
        final currentState = state;
        if (currentState is WeatherLoadedState) {
          await CacheService.instance.cacheWeatherData(currentState);
        }
        
        // Load nearby cities after getting current weather
        add(LoadNearbyCitiesEvent(
          (data['coord']['lat'] ?? 51.5074).toDouble(),
          (data['coord']['lon'] ?? -0.1278).toDouble(),
        ));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      AppLogger.logError('Failed to get current weather: $e');
      
      // Try to load cached data first
      final cachedWeather = CacheService.instance.getCachedWeatherData();
      if (cachedWeather != null) {
        AppLogger.logWarning('Using cached weather data');
        emit(cachedWeather);
        
        // Load nearby cities for cached location
        if (cachedWeather.currentLatitude != null && cachedWeather.currentLongitude != null) {
          add(LoadNearbyCitiesEvent(cachedWeather.currentLatitude!, cachedWeather.currentLongitude!));
        }
        return;
      }
      
      // Only use mock data if no cache is available
      AppLogger.logWarning('No cached data available, using mock data');
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
        currentLatitude: 51.5074,
        currentLongitude: -0.1278,
      ));
      
      // Load nearby cities for mock location
      add(LoadNearbyCitiesEvent(51.5074, -0.1278));
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
      
      // Try to load cached data first
      final cachedWeather = CacheService.instance.getCachedWeatherData();
      if (cachedWeather != null) {
        AppLogger.logWarning('Using cached weather data for location');
        emit(cachedWeather);
        
        // Load nearby cities for cached location
        if (cachedWeather.currentLatitude != null && cachedWeather.currentLongitude != null) {
          add(LoadNearbyCitiesEvent(cachedWeather.currentLatitude!, cachedWeather.currentLongitude!));
        }
        return;
      }
      
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
          currentLatitude: event.latitude,
          currentLongitude: event.longitude,
        ));
        
        // Cache the weather data
        final currentState = state;
        if (currentState is WeatherLoadedState) {
          await CacheService.instance.cacheWeatherData(currentState);
        }
        
        // Load nearby cities for the current location
        add(LoadNearbyCitiesEvent(event.latitude, event.longitude));
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
    
    // Force refresh by clearing cache and getting new data
    await CacheService.instance.clearWeatherCache();
    add(GetLocationWeatherEvent());
  }
  
  Future<void> _onLoadCachedWeather(
    LoadCachedWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Loading cached weather data...');
    
    final cachedWeather = CacheService.instance.getCachedWeatherData();
    if (cachedWeather != null) {
      AppLogger.logSuccess('Cached weather data loaded');
      emit(cachedWeather);
      
      // Load nearby cities for cached location
      if (cachedWeather.currentLatitude != null && cachedWeather.currentLongitude != null) {
        add(LoadNearbyCitiesEvent(cachedWeather.currentLatitude!, cachedWeather.currentLongitude!));
      }
    } else {
      AppLogger.logWarning('No cached weather data available');
      add(GetLocationWeatherEvent());
    }
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
  
  Future<void> _onAddCity(
    AddCityEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Adding city: ${event.cityName}');
    
    final currentState = state;
    if (currentState is! WeatherLoadedState) return;
    
    try {
      // Fetch weather for the new city
      final response = await NetworkClient.instance.getWeatherData(event.cityName);
      
      if (response.statusCode == 200) {
        final data = response.data;
        AppLogger.logSuccess('Weather data fetched for ${event.cityName}');
        
        final newCityWeather = CityWeather(
          cityName: data['name'] ?? event.cityName,
          temperature: (data['main']['temp'] ?? 0.0).toDouble(),
          condition: data['weather'][0]['main'] ?? 'Clear',
          description: data['weather'][0]['description'] ?? 'Clear sky',
          latitude: (data['coord']['lat'] ?? 0.0).toDouble(),
          longitude: (data['coord']['lon'] ?? 0.0).toDouble(),
          isNearby: false,
        );
        
        // Check if city already exists
        final existingCities = currentState.otherCities;
        final cityExists = existingCities.any((city) => 
          city.cityName.toLowerCase() == newCityWeather.cityName.toLowerCase());
        
        if (!cityExists) {
          final updatedCities = [...existingCities, newCityWeather];
          
          emit(WeatherLoadedState(
            city: currentState.city,
            temperature: currentState.temperature,
            condition: currentState.condition,
            description: currentState.description,
            humidity: currentState.humidity,
            pressure: currentState.pressure,
            visibility: currentState.visibility,
            windSpeed: currentState.windSpeed,
            forecast: currentState.forecast,
            otherCities: updatedCities,
            currentLatitude: currentState.currentLatitude,
            currentLongitude: currentState.currentLongitude,
          ));
          
          AppLogger.logSuccess('City ${event.cityName} added successfully');
        } else {
          AppLogger.logWarning('City ${event.cityName} already exists');
        }
      } else {
        throw Exception('Failed to fetch weather for ${event.cityName}');
      }
    } catch (e) {
      AppLogger.logError('Failed to add city ${event.cityName}: $e');
    }
  }
  
  Future<void> _onRemoveCity(
    RemoveCityEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Removing city: ${event.cityName}');
    
    final currentState = state;
    if (currentState is! WeatherLoadedState) return;
    
    final updatedCities = currentState.otherCities
        .where((city) => city.cityName.toLowerCase() != event.cityName.toLowerCase())
        .toList();
    
    emit(WeatherLoadedState(
      city: currentState.city,
      temperature: currentState.temperature,
      condition: currentState.condition,
      description: currentState.description,
      humidity: currentState.humidity,
      pressure: currentState.pressure,
      visibility: currentState.visibility,
      windSpeed: currentState.windSpeed,
      forecast: currentState.forecast,
      otherCities: updatedCities,
      currentLatitude: currentState.currentLatitude,
      currentLongitude: currentState.currentLongitude,
    ));
    
    AppLogger.logSuccess('City ${event.cityName} removed successfully');
  }
  
  Future<void> _onLoadNearbyCities(
    LoadNearbyCitiesEvent event,
    Emitter<WeatherState> emit,
  ) async {
    AppLogger.logBloc('Loading nearby cities for coordinates: ${event.latitude}, ${event.longitude}');
    
    final currentState = state;
    if (currentState is! WeatherLoadedState) return;
    
    try {
      // Get nearby cities based on the user's location
      final nearbyCities = _getNearbyCities(event.latitude, event.longitude);
      
      // Fetch weather for each nearby city
      final List<CityWeather> cityWeatherList = [];
      
      for (final cityInfo in nearbyCities) {
        try {
          final response = await NetworkClient.instance.getWeatherData(cityInfo['name']);
          
          if (response.statusCode == 200) {
            final data = response.data;
            
            final cityWeather = CityWeather(
              cityName: data['name'] ?? cityInfo['name'],
              temperature: (data['main']['temp'] ?? 0.0).toDouble(),
              condition: data['weather'][0]['main'] ?? 'Clear',
              description: data['weather'][0]['description'] ?? 'Clear sky',
              latitude: (data['coord']['lat'] ?? (cityInfo['lat'] as num).toDouble()).toDouble(),
              longitude: (data['coord']['lon'] ?? (cityInfo['lon'] as num).toDouble()).toDouble(),
              isNearby: true,
            );
            
            cityWeatherList.add(cityWeather);
            AppLogger.logSuccess('Weather fetched for nearby city: ${cityWeather.cityName}');
          }
        } catch (e) {
          AppLogger.logWarning('Failed to fetch weather for ${cityInfo['name']}: $e');
        }
      }
      
      // Combine nearby cities with any existing added cities
      final existingAddedCities = currentState.otherCities.where((city) => !city.isNearby).toList();
      final allCities = [...cityWeatherList, ...existingAddedCities];
      
      emit(WeatherLoadedState(
        city: currentState.city,
        temperature: currentState.temperature,
        condition: currentState.condition,
        description: currentState.description,
        humidity: currentState.humidity,
        pressure: currentState.pressure,
        visibility: currentState.visibility,
        windSpeed: currentState.windSpeed,
        forecast: currentState.forecast,
        otherCities: allCities,
        currentLatitude: currentState.currentLatitude,
        currentLongitude: currentState.currentLongitude,
      ));
      
      AppLogger.logSuccess('Loaded ${cityWeatherList.length} nearby cities');
    } catch (e) {
      AppLogger.logError('Failed to load nearby cities: $e');
    }
  }
  
  // Helper method to get nearby cities based on coordinates
  List<Map<String, dynamic>> _getNearbyCities(double latitude, double longitude) {
   
    // Define major cities around the world with their coordinates
    final worldCities = [
      // Europe
      {'name': 'Paris', 'lat': 48.8566, 'lon': 2.3522},
      {'name': 'Berlin', 'lat': 52.5200, 'lon': 13.4050},
      {'name': 'Madrid', 'lat': 40.4168, 'lon': -3.7038},
      {'name': 'Rome', 'lat': 41.9028, 'lon': 12.4964},
      {'name': 'Amsterdam', 'lat': 52.3676, 'lon': 4.9041},
      {'name': 'Vienna', 'lat': 48.2082, 'lon': 16.3738},
      {'name': 'Prague', 'lat': 50.0755, 'lon': 14.4378},
      {'name': 'Barcelona', 'lat': 41.3851, 'lon': 2.1734},
      {'name': 'Munich', 'lat': 48.1351, 'lon': 11.5820},
      {'name': 'Brussels', 'lat': 50.8503, 'lon': 4.3517},
      
      // North America
      {'name': 'New York', 'lat': 40.7128, 'lon': -74.0060},
      {'name': 'Los Angeles', 'lat': 34.0522, 'lon': -118.2437},
      {'name': 'Chicago', 'lat': 41.8781, 'lon': -87.6298},
      {'name': 'Toronto', 'lat': 43.6532, 'lon': -79.3832},
      {'name': 'Vancouver', 'lat': 49.2827, 'lon': -123.1207},
      {'name': 'Miami', 'lat': 25.7617, 'lon': -80.1918},
      {'name': 'San Francisco', 'lat': 37.7749, 'lon': -122.4194},
      {'name': 'Seattle', 'lat': 47.6062, 'lon': -122.3321},
      {'name': 'Boston', 'lat': 42.3601, 'lon': -71.0589},
      {'name': 'Montreal', 'lat': 45.5017, 'lon': -73.5673},
      
      // Asia
      {'name': 'Tokyo', 'lat': 35.6762, 'lon': 139.6503},
      {'name': 'Beijing', 'lat': 39.9042, 'lon': 116.4074},
      {'name': 'Shanghai', 'lat': 31.2304, 'lon': 121.4737},
      {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777},
      {'name': 'Delhi', 'lat': 28.7041, 'lon': 77.1025},
      {'name': 'Bangkok', 'lat': 13.7563, 'lon': 100.5018},
      {'name': 'Singapore', 'lat': 1.3521, 'lon': 103.8198},
      {'name': 'Seoul', 'lat': 37.5665, 'lon': 126.9780},
      {'name': 'Hong Kong', 'lat': 22.3193, 'lon': 114.1694},
      {'name': 'Kuala Lumpur', 'lat': 3.1390, 'lon': 101.6869},
      
      // Australia & Oceania
      {'name': 'Sydney', 'lat': -33.8688, 'lon': 151.2093},
      {'name': 'Melbourne', 'lat': -37.8136, 'lon': 144.9631},
      {'name': 'Brisbane', 'lat': -27.4698, 'lon': 153.0251},
      {'name': 'Perth', 'lat': -31.9505, 'lon': 115.8605},
      {'name': 'Auckland', 'lat': -36.8485, 'lon': 174.7633},
      
      // Africa
      {'name': 'Cairo', 'lat': 30.0444, 'lon': 31.2357},
      {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
      {'name': 'Lagos', 'lat': 6.5244, 'lon': 3.3792},
      {'name': 'Johannesburg', 'lat': -26.2041, 'lon': 28.0473},
      {'name': 'Nairobi', 'lat': -1.2921, 'lon': 36.8219},
      
      // South America
      {'name': 'São Paulo', 'lat': -23.5505, 'lon': -46.6333},
      {'name': 'Rio de Janeiro', 'lat': -22.9068, 'lon': -43.1729},
      {'name': 'Buenos Aires', 'lat': -34.6118, 'lon': -58.3960},
      {'name': 'Lima', 'lat': -12.0464, 'lon': -77.0428},
      {'name': 'Bogotá', 'lat': 4.7110, 'lon': -74.0721},
      
      // Middle East
      {'name': 'Dubai', 'lat': 25.2048, 'lon': 55.2708},
      {'name': 'Istanbul', 'lat': 41.0082, 'lon': 28.9784},
      {'name': 'Tel Aviv', 'lat': 32.0853, 'lon': 34.7818},
      {'name': 'Riyadh', 'lat': 24.7136, 'lon': 46.6753},
      {'name': 'Doha', 'lat': 25.2854, 'lon': 51.5310},
    ];
    
    // Calculate distances and sort by proximity
    final citiesWithDistance = worldCities.map((city) {
      final distance = LocationService.instance.calculateDistance(
        latitude,
        longitude,
        (city['lat'] as num).toDouble(),
        (city['lon'] as num).toDouble(),
      );
      return {
        ...city,
        'distance': distance,
      };
    }).toList();
    
    // Sort by distance and take the closest 3 cities (excluding if too close - likely same city)
    citiesWithDistance.sort((a, b) {
      final distanceA = a['distance'] as double;
      final distanceB = b['distance'] as double;
      return distanceA.compareTo(distanceB);
    });
    
    // Filter out cities that are too close (likely the same city) and take top 3
    final nearbyCities = citiesWithDistance
        .where((city) => (city['distance'] as double) > 10000) // More than 10km away
        .take(3)
        .toList();
    
    AppLogger.logInfo('Found ${nearbyCities.length} nearby cities for coordinates: $latitude, $longitude');
    for (final city in nearbyCities) {
      final distance = (city['distance'] as double) / 1000;
      AppLogger.logInfo('  - ${city['name']}: ${distance.toStringAsFixed(1)} km away');
    }
    
    return nearbyCities;
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
