import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class PushNotificationsMix {
  
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid
          );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // onDidReceiveNotificationResponse: (NotificationResponse response) {
          // debugPrint('Notification clicked: ${response.payload}');
        // },
      );
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
     int? id,
    // String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'order_channel_id',
        'Order Updates',
        channelDescription: 'Notifications about order status updates.',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id!,
        title,
        body,
        notificationDetails,
        // payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static void cancelAllNotifications() {
    _flutterLocalNotificationsPlugin.cancelAll();
  }
}


