import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'core/services/logger_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show a local notification when app is in background/terminated
  final data = message.data;
  final title = message.notification?.title ?? data['title']?.toString() ?? 'Notification';
  final body = message.notification?.body ?? data['body']?.toString() ?? 'You have a new update';
  await NotificationService().showLocalNotification(
    id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
    title: title,
    body: body,
  );
}

void main() async {
  // Ensure binding is initialized before using any platform channels
  WidgetsFlutterBinding.ensureInitialized();
  // Override debugPrint function to capture all prints
  debugPrint = capturePrint;

  // Register background handler for notifications (outside the app)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await mainApp();
}
