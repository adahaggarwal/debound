import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/app_logger.dart';

class LocationService {
  static LocationService? _instance;
  
  LocationService._();
  
  static LocationService get instance {
    _instance ??= LocationService._();
    return _instance!;
  }

  /// Check if location permission is already granted
  Future<bool> isLocationPermissionGranted() async {
    AppLogger.logInfo('🗺️ Checking location permission status');
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      bool isGranted = permission == LocationPermission.always || 
                      permission == LocationPermission.whileInUse;
      
      AppLogger.logInfo('Location permission status: $permission');
      AppLogger.logInfo('Location permission granted: $isGranted');
      
      return isGranted;
    } catch (e) {
      AppLogger.logError('Error checking location permission: $e');
      return false;
    }
  }

  /// Determine the current position of the device with proper permission handling
  Future<LocationData?> getCurrentLocationWithPermission() async {
    AppLogger.logInfo('🌍 Getting current location with permission handling...');
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.logError('Location services are disabled');
        return null;
      }
      
      AppLogger.logSuccess('Location services are enabled');
      
      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      AppLogger.logInfo('Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        AppLogger.logInfo('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          AppLogger.logError('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.logError('Location permissions are permanently denied');
        return null;
      }
      
      AppLogger.logSuccess('Location permission granted: $permission');
      
      // Get current position
      AppLogger.logInfo('Fetching current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      AppLogger.logSuccess('Position obtained: ${position.latitude}, ${position.longitude}');
      
      // Convert coordinates to city name using geocoding
      String cityName = await _getCityNameFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      LocationData locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
      );

      AppLogger.logSuccess('Location data: $locationData');
      return locationData;
      
    } catch (e) {
      AppLogger.logError('Error getting current location: $e');
      
      // Try to get last known position as fallback
      try {
        AppLogger.logInfo('Trying to get last known position as fallback...');
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        
        if (lastPosition != null) {
          AppLogger.logInfo('Last known position found: ${lastPosition.latitude}, ${lastPosition.longitude}');
          
          String cityName = await _getCityNameFromCoordinates(
            lastPosition.latitude, 
            lastPosition.longitude,
          );
          
          LocationData locationData = LocationData(
            latitude: lastPosition.latitude,
            longitude: lastPosition.longitude,
            cityName: cityName,
          );
          
          AppLogger.logSuccess('Using last known location: $locationData');
          return locationData;
        }
      } catch (fallbackError) {
        AppLogger.logError('Error getting last known position: $fallbackError');
      }
      
      return null;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    AppLogger.logInfo('📱 Requesting location permission from system');
    
    try {
      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.logError('Location services are not enabled');
        return false;
      }
      
      LocationPermission permission = await Geolocator.requestPermission();
      bool isGranted = permission == LocationPermission.always || 
                      permission == LocationPermission.whileInUse;
      
      AppLogger.logInfo('Permission request result: $permission');
      AppLogger.logInfo('Permission granted: $isGranted');
      
      return isGranted;
    } catch (e) {
      AppLogger.logError('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get city name from coordinates using geocoding
  Future<String> _getCityNameFromCoordinates(double latitude, double longitude) async {
    try {
      AppLogger.logInfo('Getting city name for coordinates: $latitude, $longitude');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String cityName = placemark.locality ?? 
                         placemark.administrativeArea ?? 
                         placemark.subAdministrativeArea ?? 
                         'Unknown Location';
        
        AppLogger.logSuccess('City name resolved: $cityName');
        return cityName;
      } else {
        AppLogger.logWarning('No placemarks found for coordinates');
        return 'Unknown Location';
      }
    } catch (e) {
      AppLogger.logError('Error getting city name from coordinates: $e');
      return 'Unknown Location';
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      bool isEnabled = await Geolocator.isLocationServiceEnabled();
      AppLogger.logInfo('Location services enabled: $isEnabled');
      return isEnabled;
    } catch (e) {
      AppLogger.logError('Error checking location service status: $e');
      return false;
    }
  }

  /// Get location accuracy status
  Future<LocationAccuracyStatus> getLocationAccuracy() async {
    try {
      LocationAccuracyStatus accuracy = await Geolocator.getLocationAccuracy();
      AppLogger.logInfo('Location accuracy status: $accuracy');
      return accuracy;
    } catch (e) {
      AppLogger.logError('Error getting location accuracy: $e');
      return LocationAccuracyStatus.reduced;
    }
  }

  /// Listen to location updates (for future use)
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
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
