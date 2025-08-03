import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'fcm_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FCMService _fcmService = FCMService();

  Future<void> initialize(NotificationRepository repository) async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize FCM service
    await _fcmService.initialize();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      if (data.containsKey('route')) {
        // Navigate to specific route
      }
    }
  }

  Future<void> showLocalNotification({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'Default notification channel',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  Future<void> showNotificationFromEntity(
    NotificationEntity notification,
  ) async {
    await showLocalNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      payload: {'id': notification.id, 'route': notification.data?['route']},
    );
  }

  Future<void> cancelNotification(String id) async {
    await _localNotifications.cancel(id.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // FCM Service delegation methods
  Future<String?> getFCMToken() async {
    return await _fcmService.getCurrentToken();
  }

  Future<void> forceFCMTokenGeneration() async {
    await _fcmService.forceTokenGeneration();
  }

  bool get isFCMInitialized => _fcmService.isInitialized;
}
