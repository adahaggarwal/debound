import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.cityName,
    required super.temperature,
    required super.feelsLike,
    required super.main,
    required super.description,
    required super.humidity,
    required super.pressure,
    required super.visibility,
    required super.windSpeed,
    required super.windDegree,
    required super.cloudiness,
    required super.dateTime,
    required super.countryCode,
    required super.coordinates,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] ?? 0.0).toDouble(),
      feelsLike: (json['main']['feels_like'] ?? 0.0).toDouble(),
      main: json['weather'][0]['main'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      humidity: json['main']['humidity'] ?? 0,
      pressure: (json['main']['pressure'] ?? 0.0).toDouble(),
      visibility: (json['visibility'] ?? 0.0).toDouble(),
      windSpeed: (json['wind']['speed'] ?? 0.0).toDouble(),
      windDegree: (json['wind']['deg'] ?? 0.0).toDouble(),
      cloudiness: json['clouds']['all'] ?? 0,
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      countryCode: json['sys']['country'] ?? '',
      coordinates: CoordinatesModel.fromJson(json['coord']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {
        'temp': temperature,
        'feels_like': feelsLike,
        'humidity': humidity,
        'pressure': pressure,
      },
      'weather': [
        {
          'main': main,
          'description': description,
        }
      ],
      'visibility': visibility,
      'wind': {
        'speed': windSpeed,
        'deg': windDegree,
      },
      'clouds': {
        'all': cloudiness,
      },
      'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
      'sys': {
        'country': countryCode,
      },
      'coord': {
        'lat': coordinates.latitude,
        'lon': coordinates.longitude,
      },
    };
  }
}

class CoordinatesModel extends Coordinates {
  const CoordinatesModel({
    required super.latitude,
    required super.longitude,
  });

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lon'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lon': longitude,
    };
  }
}

class WeatherForecastModel extends WeatherForecast {
  const WeatherForecastModel({
    required super.cityName,
    required super.dailyForecasts,
    required super.hourlyForecasts,
  });

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['list'] ?? [];
    final List<Weather> forecasts = list
        .map((item) => WeatherModel.fromJson(item))
        .toList();

    // Separate daily and hourly forecasts
    final Map<String, List<Weather>> groupedByDay = {};
    final List<Weather> hourlyForecasts = [];

    for (final forecast in forecasts) {
      final dayKey = '${forecast.dateTime.year}-${forecast.dateTime.month}-${forecast.dateTime.day}';
      
      if (!groupedByDay.containsKey(dayKey)) {
        groupedByDay[dayKey] = [];
      }
      groupedByDay[dayKey]!.add(forecast);
      
      // Add to hourly if within next 24 hours
      if (forecast.dateTime.difference(DateTime.now()).inHours <= 24) {
        hourlyForecasts.add(forecast);
      }
    }

    // Get daily forecasts (one per day, typically noon forecast)
    final List<Weather> dailyForecasts = groupedByDay.values
        .map((dayForecasts) => dayForecasts.first)
        .toList();

    return WeatherForecastModel(
      cityName: json['city']['name'] ?? '',
      dailyForecasts: dailyForecasts,
      hourlyForecasts: hourlyForecasts,
    );
  }
}