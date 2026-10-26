import 'package:crypto_tracker/screens/news_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favourites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<NewsScreenState> _newsKey = GlobalKey<NewsScreenState>();
  final GlobalKey<FavouritesScreenState> _favouritesKey =
      GlobalKey<FavouritesScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    NewsScreen(key: _newsKey),
    FavouritesScreen(key: _favouritesKey),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1030),
        selectedItemColor: const Color(0xFFE5C687),
        unselectedItemColor: const Color(0xFFB9A9D0),
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            _homeKey.currentState?.refreshCoins();
          } else if (index == 1) {
            _newsKey.currentState?.loadNews();
          } else if (index == 2) {
            _favouritesKey.currentState?.loadFavourites();
          }

          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Watchlist'),
        ],
      ),
    );
  }
}
