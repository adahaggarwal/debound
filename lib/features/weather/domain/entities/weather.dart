import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final String main;
  final String description;
  final int humidity;
  final double pressure;
  final double visibility;
  final double windSpeed;
  final double windDegree;
  final int cloudiness;
  final DateTime dateTime;
  final String countryCode;
  final Coordinates coordinates;

  const Weather({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.main,
    required this.description,
    required this.humidity,
    required this.pressure,
    required this.visibility,
    required this.windSpeed,
    required this.windDegree,
    required this.cloudiness,
    required this.dateTime,
    required this.countryCode,
    required this.coordinates,
  });

  @override
  List<Object> get props => [
        cityName,
        temperature,
        feelsLike,
        main,
        description,
        humidity,
        pressure,
        visibility,
        windSpeed,
        windDegree,
        cloudiness,
        dateTime,
        countryCode,
        coordinates,
      ];
}

class Coordinates extends Equatable {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [latitude, longitude];
}

class WeatherForecast extends Equatable {
  final String cityName;
  final List<Weather> dailyForecasts;
  final List<Weather> hourlyForecasts;

  const WeatherForecast({
    required this.cityName,
    required this.dailyForecasts,
    required this.hourlyForecasts,
  });

  @override
  List<Object> get props => [cityName, dailyForecasts, hourlyForecasts];
}