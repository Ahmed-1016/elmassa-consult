// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers

import 'dart:io' show Platform;

import 'package:ElMassaConsult/auth-panel/user_name_and_password.dart';
import 'package:ElMassaConsult/controllers/google-sign-in-controller.dart';
import 'package:ElMassaConsult/auth-panel/SessionScreen_screen.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:flutter/material.dart'; // استيراد مكتبة Flutter لبناء واجهات المستخدم
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة
import 'package:flutter/foundation.dart' show kIsWeb;


class WelcomeScreen extends StatelessWidget {
  // تعريف كلاس شاشة الترحيب
  WelcomeScreen({super.key});
  final GoogleSignInController? _googleSignInController = !kIsWeb
      ? Get.put(GoogleSignInController())
      : null; // حقن تحكم الوصول للجوجل
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // محاذاة العناصر في العمود إلى الأعلى
          children: [
            SizedBox(
              height: Get.height / 15, // إضافة مساحة عمودية
            ),
            Container(
              child: const Text(
                "Elmassa Consult",
                textAlign: TextAlign.center, // عنوان شريط التطبيق
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Pacifico"), // تنسيق النص
              ),
            ),
            SizedBox(
              height: Get.height / 30, // إضافة مساحة عمودية
            ),
            SizedBox(
              width: 250,
              height: 250,
              child: Image.asset('assets/images/elmassa_logo.png'),
            ), // عرض الرسوم المتحركة
            Container(
              margin: EdgeInsets.only(top: 20.0), // تعيين هامش علوي
              child: const Text(
                "مرحبا بكم \nفى منظومة شركة الماسة كونسلت",
                textAlign: TextAlign.center, // عنوان شريط التطبيق
                style: TextStyle(
                    fontSize: 25,
                    color: AppConstant.appTextColor), // تنسيق النص
              ),
            ),
            SizedBox(
              height: Get.height / 10, // إضافة مساحة عمودية
            ),
            Column(
              children: [
                if (!kIsWeb && Platform.isAndroid)
                  Card(
                      elevation: 5,
                      shadowColor: const Color.fromARGB(255, 64, 3, 249),
                      child: Material(
                        child: Container(
                          // تعيين عرض الحاوية
                          height: Get.height / 10, // تعيين ارتفاع الحاوية
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  5)), // تعيين نصف قطر الزوايا
                          child: TextButton.icon(
                            onPressed: () {
                              _googleSignInController
                                  ?.signInWithGoogle(); // تسجيل الدخول بواسطة جوجل
                            },
                            icon: Image.asset(
                                'assets/images/google.png'), // أيقونة جوجل
                            label: Text(
                              "الدخول بحساب Google", // نص الزر
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppConstant.appTextColor), // تنسيق النص
                            ),
                          ),
                        ),
                      )),
                if (!kIsWeb && Platform.isWindows)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      shadowColor: Colors.blue,
                      elevation: 5,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.to(() =>
                              UserNameAndPassword()); // الانتقال الى صفحة تسجيل الدخول
                        },
                        icon: Icon(Icons.password,
                            size: 35), // أيقونة البريد الإلكتروني
                        label: Text(
                          "اسم المستخدم وكلمة السر", // نص الزر
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(
                                  255, 255, 0, 25)), // تنسيق النص
                          textAlign: TextAlign.center, // محاذاة النص في المنتصف
                        ),
                      ),
                    ),
                  ),
                if (!kIsWeb && Platform.isWindows)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      shadowColor: Colors.blue,
                      elevation: 5,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.to(() =>
                              SessionScreen()); // الانتقال الى صفحة تسجيل الدخول
                        },
                        icon: Icon(Icons.qr_code_scanner,
                            size: 35), // أيقونة البريد الإلكتروني
                        label: Text(
                          "الدخول باستخدام QR Code", // نص الزر
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(
                                  255, 255, 0, 25)), // تنسيق النص
                          textAlign: TextAlign.center, // محاذاة النص في المنتصف
                        ),
                      ),
                    ),
                  ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      shadowColor: Colors.green,
                      elevation: 5,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.to(() =>
                              UserNameAndPassword()); // الانتقال الى صفحة تسجيل الدخول
                        },
                        icon: Icon(Icons.password,
                            size: 35), // أيقونة البريد الإلكتروني
                        label: Text(
                          "اسم المستخدم وكلمة السر", // نص الزر
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstant.appTextColor), // تنسيق النص
                          textAlign: TextAlign.center, // محاذاة النص في المنتصف
                        ),
                      ),
                    ),
                  ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Card(
                      shadowColor: Colors.blue,
                      elevation: 5,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.to(() =>
                              SessionScreen()); // الانتقال الى صفحة تسجيل الدخول
                        },
                        icon: Icon(Icons.qr_code_scanner,
                            size: 35), // أيقونة البريد الإلكتروني
                        label: Text(
                          "الدخول باستخدام QR Code", // نص الزر
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstant.appTextColor), // تنسيق النص
                          textAlign: TextAlign.center, // محاذاة النص في المنتصف
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ElevatedButton(
            //   onPressed: () {
            //     Get.to(() => ResponseScreen());
            //   },
            //   child: const Text('Go to Network Request Page'),
            // ),
            const SizedBox(height: 20), // Add some spacing at the bottom
          ],
        ),
      ),
    ));
  }
}
