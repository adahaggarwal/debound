import 'package:debound/core/constants/app_colors.dart';
import 'package:debound/core/services/cache_service.dart';
import 'package:debound/features/news/presentation/bloc/news_bloc.dart';
import 'package:debound/features/news/presentation/pages/news_page.dart';
import 'package:debound/features/weather/presentation/bloc/weather_bloc.dart';
import 'package:debound/features/weather/presentation/pages/weather_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const WeatherPage(),
    const NewsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    // Check internet connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;
    
    if (hasInternet) {
      // Load fresh data when internet is available
      context.read<WeatherBloc>().add(GetLocationWeatherEvent());
      context.read<NewsBloc>().add(GetTopHeadlinesEvent());
    } else {
      // Load cached data when offline
      if (CacheService.instance.hasWeatherCache()) {
        context.read<WeatherBloc>().add(LoadCachedWeatherEvent());
      } else {
        context.read<WeatherBloc>().add(GetLocationWeatherEvent());
      }
      
      if (CacheService.instance.hasNewsCache()) {
        context.read<NewsBloc>().add(LoadCachedNewsEvent());
      } else {
        context.read<NewsBloc>().add(GetTopHeadlinesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}