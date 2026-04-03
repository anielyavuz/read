import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'inbox_service.dart';
import 'user_profile_service.dart';

/// Top-level background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log(
    'Background message: ${message.messageId}',
    name: 'NotificationService',
  );
}

/// Callback type for showing in-app banner overlay.
typedef InAppBannerCallback = void Function(String title, String body);

class NotificationService {
  final FirebaseMessaging _messaging;
  final UserProfileService _profileService;
  final InboxService _inboxService;
  bool _isListeningRefresh = false;
  bool _isForegroundListenerSetup = false;

  /// Set this from the UI layer to show in-app banners.
  InAppBannerCallback? onShowBanner;

  /// Local notifications plugin for showing FCM messages in foreground.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _fcmChannelId = 'fcm_default';
  static const _fcmChannelName = 'Notifications';

  NotificationService({
    FirebaseMessaging? messaging,
    required UserProfileService profileService,
    required InboxService inboxService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _profileService = profileService,
        _inboxService = inboxService;

  /// Request notification permission and save FCM token.
  /// Call ONLY after user is authenticated.
  Future<bool> requestPermissionAndSetup() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    // Always save token and set up listeners regardless of permission.
    // On Android, FCM messages arrive even without POST_NOTIFICATIONS;
    // local notification display may silently fail, but token must be fresh.
    await _saveFcmToken();
    _listenTokenRefresh();
    await setupForegroundListener();

    return granted;
  }

  /// Save FCM token to Firestore without requesting permission.
  /// Safe to call on every app resume — skips if user is not authenticated.
  Future<void> refreshFcmToken() async {
    await _saveFcmToken();
  }

  /// Initialize local notifications plugin for displaying foreground FCM.
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    // Create the Android notification channel explicitly.
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _fcmChannelId,
          _fcmChannelName,
          description: 'Push notifications from Bookpulse',
          importance: Importance.high,
        ),
      );
    }
  }

  /// Set up foreground FCM listener. Safe to call multiple times.
  /// Call early (e.g. from main.dart) so messages are always received.
  Future<void> setupForegroundListener() async {
    if (_isForegroundListenerSetup) return;
    _isForegroundListenerSetup = true;

    await _initLocalNotifications();

    // iOS: show notification banner even when app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Extract title/body from notification payload OR data payload
      final title = message.notification?.title ??
          message.data['title'] as String? ??
          '';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          '';

      dev.log(
        'Foreground message: $title',
        name: 'NotificationService',
      );

      if (title.isEmpty && body.isEmpty) return;

      // Save to Firestore
      _inboxService.savePushNotification(title: title, body: body);

      // Show in-app banner overlay
      if (onShowBanner != null) {
        onShowBanner!(title, body);
      } else {
        // Fallback: show system notification
        _localNotifications.show(
          message.hashCode,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _fcmChannelId,
              _fcmChannelName,
              channelDescription: 'Push notifications from Bookpulse',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      dev.log(
        'Notification tapped (background): ${message.data}',
        name: 'NotificationService',
      );

      // Save background-tapped notification to Firestore too
      final title = message.notification?.title ??
          message.data['title'] as String? ??
          '';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          '';
      if (title.isNotEmpty || body.isNotEmpty) {
        _inboxService.savePushNotification(title: title, body: body);
      }
    });
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await _messaging.getToken();
      dev.log('FCM token: $token', name: 'NotificationService');
      if (token != null) {
        await _profileService.saveFcmToken(token);
        dev.log('FCM token saved to Firestore', name: 'NotificationService');
      }
    } catch (e) {
      dev.log('FCM token save failed: $e', name: 'NotificationService');
    }
  }

  void _listenTokenRefresh() {
    if (_isListeningRefresh) return;
    _isListeningRefresh = true;
    _messaging.onTokenRefresh.listen((token) {
      dev.log('FCM token refreshed: $token', name: 'NotificationService');
      _profileService.saveFcmToken(token);
    });
  }
}
