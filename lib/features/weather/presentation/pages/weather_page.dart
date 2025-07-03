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
        title: const Text('Weather'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              AppLogger.logInfo('Location button pressed');
              
              // Check if location permission is granted
              final hasPermission = await LocationService.instance.isLocationPermissionGranted();
              
              if (hasPermission) {
                // Refresh with current location
                context.read<WeatherBloc>().add(GetLocationWeatherEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing location weather...')),
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
                      ),
                    );
                  },
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              AppLogger.logInfo('Testing API keys...');
              context.read<WeatherBloc>().add(TestApiKeysEvent());
            },
            tooltip: 'Test API Keys',
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
          _buildForecastCard(),
          const SizedBox(height: 16),
          _buildMultipleCitiesCard(),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
      elevation: 4,
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
                    '10.0 km',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.water_drop,
                    'Humidity',
                    '65%',
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
                    '5.2 m/s',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.speed,
                    'Pressure',
                    '1013 hPa',
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

  Widget _buildForecastCard() {
    return Card(
      elevation: 4,
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
              height: 100,
              child: ListView.builder(
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
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                  
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Text(
                          days[index],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          icons[index],
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${temps[index]}°C',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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

  Widget _buildMultipleCitiesCard() {
    return Card(
      elevation: 4,
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
                    
                    if (result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added city: $result')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCityWeatherItem('New York', '18°C', Icons.cloud),
            _buildCityWeatherItem('Tokyo', '25°C', Icons.wb_sunny),
            _buildCityWeatherItem('Paris', '15°C', Icons.umbrella),
          ],
        ),
      ),
    );
  }

  Widget _buildCityWeatherItem(String city, String temperature, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              city,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            temperature,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}