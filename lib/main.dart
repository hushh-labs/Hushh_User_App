import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'core/services/logger_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // If the FCM already has a notification payload, let the OS show it to avoid duplicates
    if (message.notification != null) {
      return;
    }

    final data = message.data;
    final type = data['type']?.toString();

    String title = data['title']?.toString() ?? 'Notification';
    String body = data['body']?.toString() ?? 'You have a new update';

    // Special handling for agent bid completion in background
    if (type == 'agent_bid' || data.containsKey('bidAmount')) {
      final productName = data['productName']?.toString() ?? 'Product';
      final agentName = data['agentName']?.toString() ?? 'Agent';
      final bidAmount = double.tryParse(data['bidAmount']?.toString() ?? '');
      final productPrice = double.tryParse(data['productPrice']?.toString() ?? '');
      final discountedPrice = double.tryParse(data['discountedPrice']?.toString() ?? '');

      title = 'Hushh Coins Offer!';
      if (bidAmount != null) {
        body = '$agentName offered you \$${bidAmount.toStringAsFixed(2)} for $productName';
      } else if (productPrice != null && discountedPrice != null) {
        final save = (productPrice - discountedPrice).clamp(0, double.infinity);
        body = '$agentName: new price \$${discountedPrice.toStringAsFixed(2)} (save \$${save.toStringAsFixed(2)}) for $productName';
      } else {
        body = '$agentName sent you a bid for $productName';
      }
    }

    await NotificationService().showLocalNotification(
      id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
    );
  } catch (_) {}
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
