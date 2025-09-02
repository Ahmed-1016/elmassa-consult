// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PushNotificationsMix {
  static Future<void> init() async {
    try {
      // Request permission
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        debugPrint('Notification permission granted');
      } else {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          final notification = html.Notification(
            title,
            body: body,
            icon: '/icon.png',
          );

          notification.onShow.listen((_) {
            debugPrint('Notification shown: $title');
          });

          notification.onClick.listen((_) {
            debugPrint('Notification clicked: $title');
            // Handle notification click
          });

          notification.onError.listen((error) {
            debugPrint('Notification error: $error');
          });

          notification.onClose.listen((_) {
            debugPrint('Notification closed: $title');
          });
        } else {
          debugPrint('Notification permission denied');
        }
      });
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
