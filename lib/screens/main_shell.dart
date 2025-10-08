import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    _PlaceholderTab(title: 'Recipes'),
    _PlaceholderTab(title: 'Add Recipe'),
    _PlaceholderTab(title: 'Shop'),
    ProfileScreen(),
  ];

  final List<IconData> _icons = const [
    Icons.explore_rounded,
    Icons.menu_book_rounded,
    Icons.add_rounded,
    Icons.storefront_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = const [
    'Khám phá',
    'Công thức',
    'Thêm',
    'Mua sắm',
    'Tôi',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: GNav(
              gap: 8,
              activeColor: AppTheme.primaryOrange,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
              color: AppTheme.textLight.withOpacity(0.4),
              tabs: List.generate(
                _icons.length,
                (index) => GButton(
                  icon: _icons[index],
                  text: _labels[index],
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              selectedIndex: _currentIndex,
              onTabChange: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
