import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WeatherUtils {
  static IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'clouds':
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }
  
  static Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return AppColors.sunny;
      case 'clouds':
      case 'cloudy':
        return AppColors.cloudy;
      case 'rain':
      case 'drizzle':
        return AppColors.rainy;
      case 'thunderstorm':
        return AppColors.stormy;
      case 'snow':
        return AppColors.snowy;
      case 'mist':
      case 'fog':
        return AppColors.cloudy;
      default:
        return AppColors.primary;
    }
  }
  
  static Gradient getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return AppColors.sunnyGradient;
      case 'clouds':
      case 'cloudy':
        return AppColors.cloudyGradient;
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return AppColors.rainyGradient;
      case 'snow':
      case 'mist':
      case 'fog':
        return AppColors.cloudyGradient;
      default:
        return AppColors.sunnyGradient;
    }
  }
  
  static String getWeatherDescription(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Clear sky';
      case 'clouds':
        return 'Cloudy';
      case 'rain':
        return 'Rainy';
      case 'drizzle':
        return 'Light rain';
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'snow':
        return 'Snowy';
      case 'mist':
        return 'Misty';
      case 'fog':
        return 'Foggy';
      default:
        return condition;
    }
  }
  
  static String formatTemperature(double temperature) {
    return '${temperature.round()}°C';
  }
  
  static String formatWindSpeed(double speed) {
    return '${speed.toStringAsFixed(1)} m/s';
  }
  
  static String formatHumidity(int humidity) {
    return '$humidity%';
  }
  
  static String formatPressure(double pressure) {
    return '${pressure.toStringAsFixed(0)} hPa';
  }
  
  static String formatVisibility(double visibility) {
    return '${(visibility / 1000).toStringAsFixed(1)} km';
  }
  
  static String getWindDirection(double degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 
                       'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}