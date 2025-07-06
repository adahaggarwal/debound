import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/app_logger.dart';

class CitiesService {
  static CitiesService? _instance;
  static CitiesService get instance {
    _instance ??= CitiesService._internal();
    return _instance!;
  }
  
  CitiesService._internal();
  
  static const String _savedCitiesKey = 'saved_cities';
  
  /// Save a list of cities to local storage
  Future<void> saveCities(List<String> cities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJson = json.encode(cities);
      await prefs.setString(_savedCitiesKey, citiesJson);
      AppLogger.logInfo('Saved ${cities.length} cities to local storage');
    } catch (e) {
      AppLogger.logError('Failed to save cities: $e');
    }
  }
  
  /// Get saved cities from local storage
  Future<List<String>> getSavedCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJson = prefs.getString(_savedCitiesKey);
      
      if (citiesJson != null) {
        final List<dynamic> citiesList = json.decode(citiesJson);
        final cities = citiesList.map((city) => city.toString()).toList();
        AppLogger.logInfo('Loaded ${cities.length} cities from local storage');
        return cities;
      }
    } catch (e) {
      AppLogger.logError('Failed to load saved cities: $e');
    }
    
    return [];
  }
  
  /// Add a city to saved cities
  Future<void> addCity(String cityName) async {
    try {
      final cities = await getSavedCities();
      final normalizedCityName = cityName.trim();
      
      // Check if city already exists (case insensitive)
      final exists = cities.any((city) => 
        city.toLowerCase() == normalizedCityName.toLowerCase());
      
      if (!exists) {
        cities.add(normalizedCityName);
        await saveCities(cities);
        AppLogger.logInfo('Added city: $normalizedCityName');
      } else {
        AppLogger.logWarning('City already exists: $normalizedCityName');
      }
    } catch (e) {
      AppLogger.logError('Failed to add city $cityName: $e');
    }
  }
  
  /// Remove a city from saved cities
  Future<void> removeCity(String cityName) async {
    try {
      final cities = await getSavedCities();
      cities.removeWhere((city) => 
        city.toLowerCase() == cityName.toLowerCase());
      await saveCities(cities);
      AppLogger.logInfo('Removed city: $cityName');
    } catch (e) {
      AppLogger.logError('Failed to remove city $cityName: $e');
    }
  }
  
  /// Clear all saved cities
  Future<void> clearAllCities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedCitiesKey);
      AppLogger.logInfo('Cleared all saved cities');
    } catch (e) {
      AppLogger.logError('Failed to clear saved cities: $e');
    }
  }
}
