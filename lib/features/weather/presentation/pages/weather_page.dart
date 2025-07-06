import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weather_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/widgets/location_permission_dialog.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/theme_bloc.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.logInfo('WeatherPage initialized');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Updates'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              AppLogger.logInfo('Location button pressed');
              
              // Check if location services are enabled first
              final isLocationServiceEnabled = await LocationService.instance.isLocationServiceEnabled();
              if (!isLocationServiceEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location services are disabled. Please enable them in your device settings.'),
                    duration: Duration(seconds: 5),
                  ),
                );
                return;
              }
              
              // Check if location permission is granted
              final hasPermission = await LocationService.instance.isLocationPermissionGranted();
              
              if (hasPermission) {
                // Refresh with current location
                context.read<WeatherBloc>().add(GetLocationWeatherEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Getting your location weather...')),
                );
              } else {
                // Show permission dialog
                LocationPermissionDialog.show(
                  context: context,
                  onPermissionGranted: () {
                    context.read<WeatherBloc>().add(GetLocationWeatherEvent());
                  },
                  onPermissionDenied: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is needed for local weather'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                );
              }
            },
          ),
         
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              CustomBottomSheet.show(
                context: context,
                title: 'Settings',
                child: const SettingsBottomSheet(),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WeatherBloc>().add(RefreshWeatherEvent());
        },
        child: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoadingState) {
              return const LoadingWidget();
            } else if (state is WeatherLoadedState) {
              return _buildWeatherContent(state);
            } else if (state is WeatherErrorState) {
              return CustomErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<WeatherBloc>().add(GetCurrentWeatherEvent());
                },
              );
            }
            return const Center(
              child: Text('Welcome to Weather Dashboard'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeatherContent(WeatherLoadedState state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentWeatherCard(state),
          const SizedBox(height: 16),
          _buildWeatherDetailsCard(state),
          const SizedBox(height: 16),
          _buildForecastCard(state),
          const SizedBox(height: 16),
          _buildMultipleCitiesCard(state),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherLoadedState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: WeatherUtils.getWeatherGradient(state.condition),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state.city,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WeatherUtils.formatTemperature(state.temperature),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    state.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Icon(
                WeatherUtils.getWeatherIcon(state.condition),
                color: Colors.white,
                size: 80,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsCard(WeatherLoadedState state) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.visibility,
                    'Visibility',
                    '${state.visibility?.toStringAsFixed(1) ?? '10.0'} km',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.water_drop,
                    'Humidity',
                    '${state.humidity?.toInt() ?? 65}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.air,
                    'Wind Speed',
                    '${state.windSpeed?.toStringAsFixed(1) ?? '5.2'} m/s',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.speed,
                    'Pressure',
                    '${state.pressure?.toInt() ?? 1013} hPa',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard(WeatherLoadedState state) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5-Day Forecast',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: state.forecast != null && state.forecast!.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.forecast!.length,
                      itemBuilder: (context, index) {
                        final forecast = state.forecast![index];
                        
                        // Format day names
                        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final dayName = dayNames[forecast.date.weekday - 1];
                        
                        return Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                WeatherUtils.getWeatherIcon(forecast.condition),
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${forecast.maxTemp.round()}°',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${forecast.minTemp.round()}°',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final icons = [
                          Icons.wb_sunny,
                          Icons.cloud,
                          Icons.umbrella,
                          Icons.wb_sunny,
                          Icons.cloud,
                        ];
                        final temps = [22, 19, 16, 24, 20];
                        
                        // Get current date and add days
                        final now = DateTime.now();
                        final forecastDate = now.add(Duration(days: index + 1));
                        
                        // Format day names
                        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final dayName = dayNames[forecastDate.weekday - 1];
                        
                        return Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                icons[index],
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${temps[index]}°',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${temps[index] - 5}°',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleCitiesCard(WeatherLoadedState state) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Other Cities',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await CustomBottomSheet.show<String>(
                      context: context,
                      title: 'Add City',
                      child: const AddCityBottomSheet(),
                    );
                    
                    if (result != null && result.isNotEmpty) {
                      context.read<WeatherBloc>().add(AddCityEvent(result));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Adding weather for $result...')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.otherCities.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading nearby cities...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...state.otherCities.map((cityWeather) => _buildCityWeatherItem(
                cityWeather,
                state,
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCityWeatherItem(CityWeather cityWeather, WeatherLoadedState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            WeatherUtils.getWeatherIcon(cityWeather.condition),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cityWeather.cityName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (cityWeather.isNearby) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.near_me,
                        size: 12,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
                Text(
                  cityWeather.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            WeatherUtils.formatTemperature(cityWeather.temperature),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!cityWeather.isNearby) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                context.read<WeatherBloc>().add(RemoveCityEvent(cityWeather.cityName));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed ${cityWeather.cityName}')),
                );
              },
              tooltip: 'Remove city',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// Settings Bottom Sheet
class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Temperature Unit Setting
        ListTile(
          leading: const Icon(Icons.thermostat),
          title: const Text('Temperature Unit'),
          subtitle: Text(SettingsService.instance.getTemperatureUnitName()),
          trailing: Switch(
            value: SettingsService.instance.getTemperatureUnit() == TemperatureUnit.fahrenheit,
            onChanged: (value) async {
              final unit = value ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;
              await SettingsService.instance.setTemperatureUnit(unit);
              setState(() {});
              
              // Show a snackbar to indicate the change
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Temperature unit changed to ${SettingsService.instance.getTemperatureUnitName()}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        
        // Theme Setting
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            ThemeMode currentTheme = ThemeMode.system;
            if (state is ThemeLoaded) {
              currentTheme = state.themeMode;
            }
            
            return ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme'),
              subtitle: Text(_getThemeDisplayName(currentTheme)),
              trailing: PopupMenuButton<ThemeMode>(
                onSelected: (ThemeMode mode) {
                  context.read<ThemeBloc>().add(ChangeThemeEvent(mode));
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                child: const Icon(Icons.arrow_drop_down),
              ),
            );
          },
        ),
        
        // Location Setting
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Default Location'),
          subtitle: const Text('Current Location'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location settings feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        
        // Weather Alerts Setting
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Weather Alerts'),
          subtitle: const Text('Enabled'),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Weather alerts feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
  
  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }
}

class AddCityBottomSheet extends StatefulWidget {
  const AddCityBottomSheet({super.key});

  @override
  State<AddCityBottomSheet> createState() => _AddCityBottomSheetState();
}

class _AddCityBottomSheetState extends State<AddCityBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'City Name',
            hintText: 'Enter city name (e.g., Paris, Tokyo)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: _isLoading ? null : (value) => _addCity(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _addCity,
              child: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add City'),
            ),
          ],
        ),
      ],
    );
  }

  void _addCity() {
    final city = _controller.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city name')),
      );
      return;
    }
    
    if (city.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City name must be at least 2 characters')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate a brief delay to show loading state
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop(city);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
