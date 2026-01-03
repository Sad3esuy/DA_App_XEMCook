import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/push_notification_service.dart';

import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/favorite_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.initialize();

  // Cấu hình status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<FavoriteState>(
          create: (_) => FavoriteState(),
        ),
      ],
      child: const XEMCookApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization error: $error');
  }
}

class XEMCookApp extends StatelessWidget {
  const XEMCookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XEMCook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainShell(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _checkFirstTimeAndAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeAndAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Kiểm tra xem đây có phải lần đầu mở app không
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      // Lần đầu tiên -> hiển thị Welcome Screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const WelcomeScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // Không phải lần đầu -> kiểm tra trạng thái đăng nhập
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const MainShell();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 66, 107, 93), // Hoặc một màu bất kỳ bạn muốn
      ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/app_icon_v2.png',
                          width: 400,
                          height: 400,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App name
                      Text(
                        'XEMCook',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Color.fromARGB(0, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Công thức nấu ăn là bạn',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 24,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Bạn là công thức',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 24,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
