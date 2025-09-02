// ignore_for_file: file_names, avoid_unnecessary_containers, prefer_const_constructors, deprecated_member_use

import 'dart:async'; // استيراد مكتبة المؤقتات
import 'dart:io';
import 'package:ElMassaConsult/auth-panel/user_name_and_password.dart';
import 'package:ElMassaConsult/auth-panel/welcome-screen.dart';
import 'package:ElMassaConsult/office_app/general/admin_screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen.dart';
import 'package:ElMassaConsult/controllers/get-user-data-controller.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // استيراد مكتبة Flutter لبناء واجهات المستخدم
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:permission_handler/permission_handler.dart'; // مكتبة لإدارة الأذونات

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
    if (!kIsWeb && Platform.isAndroid) {
      _requestStoragePermission(); // طلب إذن التخزين فقط على أندرويد
    }
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  


  Future<void> _navigateToNextScreen() async {
    try {
      // تأخير بسيط لمحاكاة شاشة البداية
      await Future.delayed(const Duration(seconds: 3));

      if (!kIsWeb && Platform.isAndroid) {
        try {
          // إعادة تحميل بيانات المستخدم للتحقق من حالته
          await user!.reload();
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            await FirebaseAuth.instance.signOut();
            Get.offAll(() => WelcomeScreen());
            return;
          } else {
            final prefs = await SharedPreferences.getInstance();
            final selectedCategory = prefs.getString('selectedCategory');
            final storedUsername = prefs.getString('selectedUsername');
            final storedPassword = prefs.getString('enteredPassword');

            if (storedUsername != null && storedPassword != null) {
              final collectionName = selectedCategory == "موقع"
                  ? 'siteTeamWork'
                  : 'officeTeamWork';
              final teamWorkResult = await FirebaseFirestore.instance
                  .collection(collectionName)
                  .where('username', isEqualTo: storedUsername)
                  .get();

              if (teamWorkResult.docs.isNotEmpty) {
                final teamWorkData = teamWorkResult.docs.first.data();
                if (teamWorkData['password'] == storedPassword &&
                    selectedCategory == "موقع") {
                  Get.offAll(
                    () => SiteGovScreen(
                      userName: storedUsername,
                      selectedCategory: selectedCategory!,
                    ),
                  );
                  return;
                } else {
                  if (storedUsername == "Admin") {
                    Get.offAll(
                      () => AdminScreen(
                        userName: storedUsername,
                        selectedCategory: selectedCategory!,
                      ),
                    );
                    return;
                  } else {
                    Get.offAll(
                      () => OfficeGovScreen(
                        userName: storedUsername,
                        selectedCategory: selectedCategory!,
                      ),
                    );
                    return;
                  }
                }
              }
            }

            if (user != null) {
              final GetUserDataController getUserDataController = Get.put(
                GetUserDataController(),
              );

              var userData = await getUserDataController.getUserData(user!.uid);

              if (userData.isNotEmpty && userData[0]['isAdmin'] == true) {
                // Get.offAll(() => AdminPanel()); // تحويل المستخدم إلى شاشة المسؤول
              } else {
                Get.offAll(
                  () => UserNameAndPassword(),
                ); // تحويل المستخدم إلى شاشة تسجيل الدخول
              }
            } else {
              Get.offAll(() => WelcomeScreen());
            }
          }
        } catch (e) {
          // في حالة وجود خطأ (مثل حذف الحساب) سيتم تسجيل الخروج
          await FirebaseAuth.instance.signOut();
          Get.offAll(() => WelcomeScreen());
          return;
        }
      } else {
        // للويب أو أي منصة غير أندرويد
        Get.offAll(() => WelcomeScreen());
      }
    } catch (e) {
      print('Error: $e');
      // عرض رسالة خطأ أو إعادة توجيه المستخدم إلى شاشة الخطأ
      Get.offAll(() => WelcomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0),
      body: Center(
        child: Column(
          children: [
            Container(
              child: const Text(
                "Elmassa Consult",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Pacifico",
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: Get.width / 2,
                alignment: Alignment.center,
                child: Image.asset('assets/images/elmassa_logo.png'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              width: Get.width,
              alignment: Alignment.center,
              child: Text(
                AppConstant.appPoweredBy,
                style: TextStyle(
                  color: AppConstant.appTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          ],
        ),
      ),
    );
  }
}
