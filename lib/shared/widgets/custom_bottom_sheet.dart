import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  final bool isDismissible;
  final VoidCallback? onClose;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.isDismissible = true,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    double? height,
    bool isDismissible = true,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: title,
        height: height,
        isDismissible: isDismissible,
        onClose: onClose,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose ?? () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _temperatureUnit = 'Celsius';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: AppColors.primary,
            ),
            title: const Text('Notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.thermostat,
              color: AppColors.primary,
            ),
            title: const Text('Temperature Unit'),
            trailing: DropdownButton<String>(
              value: _temperatureUnit,
              items: const [
                DropdownMenuItem(value: 'Celsius', child: Text('°C')),
                DropdownMenuItem(value: 'Fahrenheit', child: Text('°F')),
              ],
              onChanged: (value) {
                setState(() {
                  _temperatureUnit = value!;
                });
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddCityBottomSheet extends StatefulWidget {
  const AddCityBottomSheet({super.key});

  @override
  State<AddCityBottomSheet> createState() => _AddCityBottomSheetState();
}

class _AddCityBottomSheetState extends State<AddCityBottomSheet> {
  final TextEditingController _cityController = TextEditingController();
  final List<String> _suggestedCities = [
    'New York',
    'London',
    'Tokyo',
    'Paris',
    'Berlin',
    'Sydney',
    'Dubai',
    'Singapore',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Enter city name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Cities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _suggestedCities.length,
              itemBuilder: (context, index) {
                final city = _suggestedCities[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, city);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        city,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_cityController.text.isNotEmpty) {
                  Navigator.pop(context, _cityController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add City'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}