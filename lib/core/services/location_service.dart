import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';
import '../error/failures.dart';

class LocationService {
  static LocationService? _instance;
  
  LocationService._();
  
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    AppLogger.logInfo('🗺️ Requesting location permission...');
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.logWarning('Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      AppLogger.logInfo('Current location permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.logError('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.logError('Location permissions are permanently denied');
        return false;
      }

      AppLogger.logSuccess('Location permission granted');
      return true;
    } catch (e) {
      AppLogger.logError('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    AppLogger.logInfo('📍 Getting current position...');
    
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw const LocationFailure('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.logSuccess('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      AppLogger.logError('Error getting current position: $e');
      return null;
    }
  }

  /// Get city name from coordinates
  Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
    AppLogger.logInfo('🏙️ Getting city name from coordinates...');
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String cityName = place.locality ?? place.administrativeArea ?? 'Unknown';
        
        AppLogger.logSuccess('City name: $cityName');
        return cityName;
      }
    } catch (e) {
      AppLogger.logError('Error getting city name: $e');
    }
    
    return null;
  }

  /// Get user's current location and city
  Future<LocationData?> getCurrentLocationData() async {
    AppLogger.logInfo('🌍 Getting current location data...');
    
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      String? cityName = await getCityFromCoordinates(
        position.latitude, 
        position.longitude,
      );

      LocationData locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName ?? 'Unknown City',
      );

      AppLogger.logSuccess('Location data retrieved: ${locationData.cityName}');
      return locationData;
    } catch (e) {
      AppLogger.logError('Error getting location data: $e');
      return null;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Open app settings for location permission
  Future<void> openLocationSettings() async {
    AppLogger.logInfo('Opening location settings...');
    await Geolocator.openAppSettings();
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String cityName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, city: $cityName)';
  }
}