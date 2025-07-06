# Debound - Weather & News Dashboard

A Flutter application that provides weather information and news updates in a clean, modern interface.

## Features

- 🌤️ Real-time weather information
- 📰 Latest news from various categories
- 🌍 Multiple city weather support
- 🌙 Dark/Light theme toggle
- 📱 Responsive design
- 💾 Offline caching
- 🔔 Smart notifications

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd debound
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Get your API keys:
   - **Weather API**: Sign up at [OpenWeatherMap](https://openweathermap.org/api) and get your free API key
   - **News API**: Sign up at [NewsAPI](https://newsapi.org/) and get your free API key

3. Edit the `.env` file and add your API keys:
   ```
   WEATHER_API_KEY=your_actual_weather_api_key_here
   NEWS_API_KEY=your_actual_news_api_key_here
   ```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/         # App constants and configuration
│   ├── network/          # Network clients and services
│   ├── services/         # Business logic services
│   ├── theme/            # Theme configuration
│   └── utils/            # Utility functions
├── features/
│   ├── splash/           # Splash screen
│   ├── weather/          # Weather feature
│   └── news/             # News feature
└── main.dart             # App entry point
```

## Environment Variables

The app uses the following environment variables:

- `WEATHER_API_KEY`: Your OpenWeatherMap API key
- `NEWS_API_KEY`: Your NewsAPI key

**Important**: Never commit your `.env` file to version control. It's already added to `.gitignore`.

## API Keys

### OpenWeatherMap API
- **URL**: https://openweathermap.org/api
- **Free Tier**: 1,000 calls/day, 60 calls/minute
- **Features Used**: Current weather, 5-day forecast

### NewsAPI
- **URL**: https://newsapi.org/
- **Free Tier**: 1,000 requests/day
- **Features Used**: Top headlines, everything endpoint

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues:

1. Check that your API keys are valid and correctly set in the `.env` file
2. Ensure you have a stable internet connection
3. Check the console logs for any error messages
4. Make sure you're using the latest version of Flutter

For additional support, please open an issue in the GitHub repository.
