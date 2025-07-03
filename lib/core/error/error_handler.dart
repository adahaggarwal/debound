import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is Exception) {
      return UnexpectedFailure(error.toString());
    } else {
      return const UnexpectedFailure('An unexpected error occurred');
    }
  }
  
  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
        
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
        
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled');
        
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');
        
      case DioExceptionType.unknown:
        return const NetworkFailure('Network error occurred');
        
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Certificate error');
    }
  }
  
  static Failure _handleResponseError(Response? response) {
    if (response == null) {
      return const ServerFailure('No response from server');
    }
    
    switch (response.statusCode) {
      case 400:
        return const ServerFailure('Bad request');
      case 401:
        return const ServerFailure('Unauthorized access');
      case 403:
        return const ServerFailure('Forbidden access');
      case 404:
        return const ServerFailure('Resource not found');
      case 429:
        return const ServerFailure('Too many requests');
      case 500:
        return const ServerFailure('Internal server error');
      case 502:
        return const ServerFailure('Bad gateway');
      case 503:
        return const ServerFailure('Service unavailable');
      default:
        return ServerFailure('Server error: ${response.statusCode}');
    }
  }
}