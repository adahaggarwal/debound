import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'WeatherNewsApp';

  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        time: DateTime.now(),
      );
    }
  }

  static void logInfo(String message, {String? tag}) {
    log('ℹ️ INFO: $message', tag: tag);
  }

  static void logSuccess(String message, {String? tag}) {
    log('✅ SUCCESS: $message', tag: tag);
  }

  static void logWarning(String message, {String? tag}) {
    log('⚠️ WARNING: $message', tag: tag);
  }

  static void logError(String message, {String? tag}) {
    log('❌ ERROR: $message', tag: tag);
  }

  static void logNetwork(String message, {String? tag}) {
    log('🌐 NETWORK: $message', tag: tag ?? 'NetworkClient');
  }

  static void logApi(String message, {String? tag}) {
    log('🔑 API: $message', tag: tag ?? 'ApiClient');
  }

  static void logWeather(String message) {
    log('🌤️ WEATHER: $message', tag: 'WeatherAPI');
  }

  static void logNews(String message) {
    log('📰 NEWS: $message', tag: 'NewsAPI');
  }

  static void logBloc(String message, {String? tag}) {
    log('🏗️ BLOC: $message', tag: tag ?? 'BlocState');
  }

  static void logRequest(String method, String url, Map<String, dynamic>? params) {
    logNetwork('REQUEST: $method $url');
    if (params != null && params.isNotEmpty) {
      logNetwork('PARAMS: ${params.toString()}');
    }
  }

  static void logResponse(String url, int statusCode, dynamic data) {
    logNetwork('RESPONSE: $url - Status: $statusCode');
    if (data != null) {
      logNetwork('DATA: ${data.toString().substring(0, data.toString().length > 200 ? 200 : data.toString().length)}...');
    }
  }

  static void logApiKey(String apiName, String key) {
    final maskedKey = key.length > 8 
        ? '${key.substring(0, 4)}...${key.substring(key.length - 4)}'
        : key.replaceAll(RegExp(r'.'), '*');
    logApi('$apiName API Key: $maskedKey');
  }
}