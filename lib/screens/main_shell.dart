import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'recipes_screen.dart';
import 'recipe_form_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Tab roots
  final List<Widget> _tabRoots = const [
    HomeScreen(),
    RecipesScreen(),
    RecipeFormScreen(),
    _PlaceholderTab(title: 'Shop'),
    ProfileScreen(),
  ];

  // Separate navigator for each tab so pushes keep bottom bar visible
  late final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_tabRoots.length, (_) => GlobalKey<NavigatorState>());

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

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  List<Widget> _buildTabNavigators() {
    return List.generate(_tabRoots.length, (index) {
      return Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (_) => _tabRoots[index],
            settings: settings,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _buildTabNavigators(),
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
                onTabChange: (index) {
                  if (index == _currentIndex) {
                    final nav = _navigatorKeys[index].currentState;
                    nav?.popUntil((route) => route.isFirst);
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },
              ),
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
