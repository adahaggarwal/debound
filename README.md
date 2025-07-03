# Weather & News Dashboard App

A Flutter application that provides weather information and news updates in a clean, modern interface. This project demonstrates advanced Flutter concepts, API integration, and modern development practices.

## 🌟 Features

### Weather Section
- **Current Weather**: Location-based weather display with animated weather icons
- **5-Day Forecast**: Detailed weather forecast with hourly breakdown
- **Multiple Cities**: Compare weather across different cities
- **Weather Alerts**: Push notifications for weather updates
- **Pull-to-Refresh**: Update weather data with a simple pull gesture
- **Offline Mode**: Cached weather data for offline viewing

### News Section
- **Top Headlines**: Latest news with category filtering (Business, Tech, Sports, etc.)
- **Article Search**: Search functionality with debounced input
- **Bookmark Articles**: Save articles for offline reading
- **Share Articles**: Share interesting articles with others
- **Category Filters**: Filter news by categories

### User Experience
- **Dark/Light Theme**: System preference support with manual toggle
- **Smooth Animations**: Micro-interactions and smooth transitions
- **Responsive Design**: Works on different screen sizes
- **Loading States**: Skeleton screens and progress indicators
- **Error Handling**: Comprehensive error states with retry options

## 🏗️ Architecture

This project follows **Clean Architecture** principles with a feature-based folder structure:

```
lib/
├── core/
│   ├── constants/          # App constants, colors, themes
│   ├── error/             # Error handling and failures
│   ├── network/           # Network client and API calls
│   └── utils/             # Utility functions and helpers
├── features/
│   ├── weather/
│   │   ├── data/          # Data models and repositories
│   │   ├── domain/        # Business logic and entities
│   │   └── presentation/  # UI components and BLoC
│   └── news/
│       ├── data/          # Data models and repositories
│       ├── domain/        # Business logic and entities
│       └── presentation/  # UI components and BLoC
└── shared/
    └── widgets/           # Reusable UI components
```

## 📦 Dependencies

### Core Dependencies
- **flutter_bloc**: State management
- **equatable**: Object equality
- **dio**: HTTP client for API calls
- **connectivity_plus**: Network connectivity checks

### UI Dependencies
- **shimmer**: Loading animations
- **lottie**: Advanced animations
- **cached_network_image**: Image caching
- **pull_to_refresh**: Pull-to-refresh functionality

### Storage Dependencies
- **hive**: Local database
- **shared_preferences**: Simple key-value storage

### Location Dependencies
- **geolocator**: Location services
- **geocoding**: Address geocoding

### Utility Dependencies
- **intl**: Internationalization
- **url_launcher**: Open URLs
- **share_plus**: Share functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.7.2)
- Dart SDK (>=3.7.2)
- Android Studio / VS Code
- API Keys (see below)

### API Keys Required

1. **OpenWeatherMap API**
   - Go to [OpenWeatherMap](https://openweathermap.org/api)
   - Create an account and get your free API key
   - Replace `YOUR_WEATHER_API_KEY` in `lib/core/constants/app_constants.dart`

2. **NewsAPI**
   - Go to [NewsAPI](https://newsapi.org/)
   - Create an account and get your free API key
   - Replace `YOUR_NEWS_API_KEY` in `lib/core/constants/app_constants.dart`

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd debound
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Add API Keys**
   - Open `lib/core/constants/app_constants.dart`
   - Replace placeholder API keys with your actual keys

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Keys Setup
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String weatherApiKey = 'your_openweathermap_api_key_here';
  static const String newsApiKey = 'your_newsapi_key_here';
}
```

### Location Permissions
The app requires location permissions for weather data. Make sure to:

**Android**: Update `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS**: Update `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show weather information.</string>
```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📱 Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🎨 Design Principles

- **Material Design 3**: Modern Material You design system
- **Responsive UI**: Adapts to different screen sizes
- **Accessibility**: Proper contrast ratios and semantic markup
- **Performance**: Efficient rendering and smooth animations
- **Offline Support**: Cached data for offline usage

## 🔄 State Management

The app uses **BLoC (Business Logic Component)** pattern for state management:

- **Events**: User actions and system events
- **States**: UI states (loading, loaded, error)
- **BLoC**: Business logic that transforms events into states

## 🌐 Network Layer

- **Dio**: HTTP client with interceptors
- **Error Handling**: Comprehensive error scenarios
- **Caching**: Smart caching strategies
- **Connectivity**: Network connectivity checks

## 📊 Performance Optimizations

- **Image Caching**: Cached network images
- **Lazy Loading**: Efficient list rendering
- **Debounced Search**: Optimized search functionality
- **Memory Management**: Proper disposal of resources

## 🔒 Security

- **API Keys**: Secure API key management
- **HTTPS**: All API calls use HTTPS
- **Input Validation**: Secure input handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenWeatherMap](https://openweathermap.org/) for weather data
- [NewsAPI](https://newsapi.org/) for news data
- [Flutter](https://flutter.dev/) for the amazing framework
- [Material Design](https://material.io/) for design guidelines

---

**Note**: This is a sample application created for educational purposes. Please ensure you comply with the terms of service of the APIs used.