import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

enum TemperatureUnit { celsius, fahrenheit }

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance {
    _instance ??= SettingsService._();
    return _instance!;
  }
  
  SettingsService._();
  
  SharedPreferences? _prefs;
  
  /// Initialize settings service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.logSuccess('SettingsService initialized');
    } catch (e) {
      AppLogger.logError('Failed to initialize SettingsService: $e');
    }
  }
  
  /// Get temperature unit
  TemperatureUnit getTemperatureUnit() {
    if (_prefs == null) return TemperatureUnit.celsius;
    
    final unitString = _prefs!.getString(AppConstants.temperatureUnitKey) ?? 'celsius';
    return unitString == 'fahrenheit' ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;
  }
  
  /// Set temperature unit
  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    if (_prefs == null) await initialize();
    
    final unitString = unit == TemperatureUnit.fahrenheit ? 'fahrenheit' : 'celsius';
    await _prefs!.setString(AppConstants.temperatureUnitKey, unitString);
    AppLogger.logInfo('Temperature unit set to: $unitString');
  }
  
  /// Get theme mode
  String getThemeMode() {
    if (_prefs == null) return 'system';
    return _prefs!.getString(AppConstants.themeKey) ?? 'system';
  }
  
  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    if (_prefs == null) await initialize();
    
    await _prefs!.setString(AppConstants.themeKey, mode);
    AppLogger.logInfo('Theme mode set to: $mode');
  }
  
  /// Format temperature based on user preference
  String formatTemperature(double celsius) {
    final unit = getTemperatureUnit();
    
    if (unit == TemperatureUnit.fahrenheit) {
      final fahrenheit = (celsius * 9/5) + 32;
      return '${fahrenheit.round()}°F';
    } else {
      return '${celsius.round()}°C';
    }
  }
  
  /// Get temperature unit symbol
  String getTemperatureUnitSymbol() {
    final unit = getTemperatureUnit();
    return unit == TemperatureUnit.fahrenheit ? '°F' : '°C';
  }
  
  /// Get temperature unit name
  String getTemperatureUnitName() {
    final unit = getTemperatureUnit();
    return unit == TemperatureUnit.fahrenheit ? 'Fahrenheit' : 'Celsius';
  }
}