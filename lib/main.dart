import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/weather/presentation/bloc/weather_bloc.dart';
import 'features/news/presentation/bloc/news_bloc.dart';
import 'core/network/network_client.dart';
import 'core/utils/app_logger.dart';
import 'core/services/saved_news_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/cache_service.dart';
import 'core/theme/theme_bloc.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.logInfo('🚀 Starting Weather & News Dashboard App');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.logSuccess('Environment variables loaded');
    
    // Validate API keys
    if (!AppConstants.areApiKeysValid) {
      AppLogger.logError('⚠️ API keys not found or invalid. Please check your .env file.');
      AppLogger.logInfo('Make sure you have copied .env.example to .env and filled in your API keys.');
    } else {
      AppLogger.logSuccess('✅ API keys validated successfully');
    }
  } catch (e) {
    AppLogger.logError('❌ Failed to load environment variables: $e');
    AppLogger.logInfo('Please ensure you have a .env file with your API keys.');
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  AppLogger.logSuccess('Hive initialized');
  
  // Initialize shared preferences
  await SharedPreferences.getInstance();
  AppLogger.logSuccess('SharedPreferences initialized');
  
  // Initialize saved news service
  await SavedNewsService.instance.initialize();
  AppLogger.logSuccess('SavedNewsService initialized');
  
  // Initialize settings service
  await SettingsService.instance.initialize();
  AppLogger.logSuccess('SettingsService initialized');
  
  // Initialize cache service
  await CacheService.instance.initialize();
  AppLogger.logSuccess('CacheService initialized');
  
  // Initialize Network Client (this will log API key status)
  NetworkClient.instance;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => WeatherBloc()),
        BlocProvider(create: (context) => NewsBloc()),
        BlocProvider(create: (context) => ThemeBloc()..add(InitializeThemeEvent())),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          ThemeMode currentThemeMode = ThemeMode.system;
          if (state is ThemeLoaded) {
            currentThemeMode = state.themeMode;
          }
          
          return MaterialApp(
            title: 'Weather & News Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentThemeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
