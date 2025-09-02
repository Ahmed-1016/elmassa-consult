import 'package:ElMassaConsult/auth-panel/splash-screen.dart';
import 'package:ElMassaConsult/firebase_options.dart';
import 'package:ElMassaConsult/services/notifications/notif.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// دالة استدعاء عند استقبال رسالة في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationsMix.init(); // تهيئة التنبيهات لو مش مهيأة

  // عرض إشعار باستخدام flutter_local_notifications
  await PushNotificationsMix.showNotification(
    id: message.hashCode,
    title: message.notification?.title ?? "عنوان افتراضي",
    body: message.notification?.body ?? "نص الإشعار",
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await PushNotificationsMix.init();

  if (!kIsWeb && Platform.isAndroid) {
    await [Permission.notification, Permission.storage].request();
  }

  runApp(MyApp()); //تشغيل التطبيق
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      locale: Locale("ar"),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //الشاشة الرئيسية
      builder: EasyLoading.init(), //تهيئة الloading
    );
  }
}
