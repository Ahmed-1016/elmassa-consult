// ignore_for_file: avoid_print, file_names

import 'package:firebase_messaging/firebase_messaging.dart';

Future<String> getCustomerDeviceToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    return token!;
  } catch (e) {
    print("Error");
    throw Exception("Error");
  }
}
