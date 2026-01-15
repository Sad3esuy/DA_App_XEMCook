import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../theme/app_theme.dart';
//import 'favorite_screen.dart';
import 'home_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import 'shopping/shopping_list_screen.dart';
import 'recipe/my_recipes_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _showNavNotifier = ValueNotifier<bool>(true);

  // Tab roots
  final List<Widget> _tabRoots = const [
    HomeScreen(),
    SearchScreen(),
    MyRecipesScreen(),
    ShoppingListScreen(),
    ProfileScreen(),
  ];


  // Separate navigator for each tab so pushes keep bottom bar visible
  late final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_tabRoots.length, (_) => GlobalKey<NavigatorState>());

  final List<IconData> _icons = const [
    Icons.explore_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
    Icons.shopping_bag_outlined,
    Icons.person_rounded,
  ];


  final List<String> _labels = const [
    'Khám phá',
    'Tìm kiếm',
    'Công thức',
    'Mua sắm',
    'Tài khoản',
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavVisibility());
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      _updateNavVisibility();
      return false;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      _updateNavVisibility(forcedIndex: 0);
      return false;
    }
    return true;
  }

  List<Widget> _buildTabNavigators() {
    return List.generate(_tabRoots.length, (index) {
      return Navigator(
        key: _navigatorKeys[index],
        observers: [
          _TabNavigatorObserver(
            onStackChanged: () => _updateNavVisibility(),
          ),
        ],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (_) => _tabRoots[index],
            settings: settings,
          );
        },
      );
    });
  }

  void _updateNavVisibility({int? forcedIndex}) {
    final nav = _navigatorKeys[forcedIndex ?? _currentIndex].currentState;
    final shouldShow = !(nav?.canPop() ?? false);
    if (_showNavNotifier.value != shouldShow) {
      _showNavNotifier.value = shouldShow;
    }
  }

  @override
  void dispose() {
    _showNavNotifier.dispose();
    super.dispose();
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
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: _showNavNotifier,
          builder: (context, visible, _) {
            if (!visible) return const SizedBox.shrink();
            return Container(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 12),
                  child: GNav(
                    gap: 6,
                    activeColor: AppTheme.primaryOrange,
                    iconSize: 24,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    duration: const Duration(milliseconds: 300),
                    tabBackgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                    color: AppTheme.textLight.withOpacity(0.4),
                    tabs: List.generate(
                      _icons.length,
                      (index) => GButton(
                        icon: _icons[index],
                        text: _labels[index],
                        textStyle: const TextStyle(
                          fontSize: 13,
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
                        _updateNavVisibility();
                      } else {
                        setState(() => _currentIndex = index);
                        _updateNavVisibility(forcedIndex: index);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  _TabNavigatorObserver({required this.onStackChanged});

  final VoidCallback onStackChanged;

  void _notify() {
    onStackChanged();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }
}


