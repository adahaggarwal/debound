import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/app_logger.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionDialog({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  static Future<bool?> show({
    required BuildContext context,
    VoidCallback? onPermissionGranted,
    VoidCallback? onPermissionDenied,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onPermissionGranted: onPermissionGranted,
        onPermissionDenied: onPermissionDenied,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Location Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'We need access to your location to show you accurate weather information for your area.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get personalized weather updates',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            AppLogger.logInfo('User denied location permission');
            Navigator.of(context).pop(false);
            onPermissionDenied?.call();
          },
          child: Text(
            'Not Now',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            AppLogger.logInfo('User requested location permission');
            
            // Request location permission
            final hasPermission = await LocationService.instance.requestLocationPermission();
            
            Navigator.of(context).pop(hasPermission);
            
            if (hasPermission) {
              onPermissionGranted?.call();
            } else {
              onPermissionDenied?.call();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Allow Location',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class LocationSettingsDialog extends StatelessWidget {
  const LocationSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LocationSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Location Disabled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'Location permission is required to show weather for your current location. Please enable location access in your device settings.',
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            AppLogger.logInfo('Opening app settings (simplified)');
            // TODO: Add real settings opening when location plugin is enabled
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Open Settings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}