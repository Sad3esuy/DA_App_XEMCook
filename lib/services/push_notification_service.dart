import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'notification_api_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();

  static bool _initialized = false;
  static String? _currentToken;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissionIfNeeded();

    _messaging.onTokenRefresh.listen((token) {
      _handleTokenUpdate(token);
    });

    final token = await _messaging.getToken();
    if (token != null) {
      await _handleTokenUpdate(token);
    }
  }

  static Future<void> _requestPermissionIfNeeded() async {
    if (kIsWeb) {
      return;
    }

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    } catch (error) {
      debugPrint('PushNotificationService: requestPermission error $error');
    }
  }

  static Future<void> _handleTokenUpdate(String token) async {
    if (token.isEmpty) {
      return;
    }
    _currentToken = token;
    await syncTokenWithBackend();
  }

  static Future<void> syncTokenWithBackend() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) {
        return;
      }
      await NotificationApiService.registerToken(
        token: _currentToken!,
        platform: _resolvePlatform(),
      );
    } catch (error) {
      debugPrint('PushNotificationService: register token failed $error');
    }
  }

  static Future<void> unregisterToken() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) {
        return;
      }
      await NotificationApiService.unregisterToken(_currentToken!);
    } catch (error) {
      debugPrint('PushNotificationService: unregister token failed $error');
    }
  }

  static String _resolvePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // already initialized
  }
  try {
    // ignore: avoid_print
    print('Handling a background message: ${message.messageId}');
  } catch (error) {
    debugPrint('Background message error: $error');
  }
}
