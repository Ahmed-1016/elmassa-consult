// ignore_for_file: file_names, unused_local_variable, unused_field, avoid_print

import 'package:ElMassaConsult/auth-panel/user_name_and_password.dart';
import 'package:flutter/material.dart';
import 'package:ElMassaConsult/controllers/get-device-token-controller.dart';
import 'package:ElMassaConsult/models/user-model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // لـ kIsWeb
import 'dart:io'; // للتحقق من المنصة

class GoogleSignInController extends GetxController {
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      if (!Platform.isWindows && !kIsWeb) {
        await googleSignIn.initialize(); // Android / iOS
      } else if (kIsWeb) {
        await googleSignIn.initialize(
          clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // عدل هنا
        );
      }
    } catch (e) {
      print("❌ فشل تهيئة Google Sign-In: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    final GetDeviceTokenController getDeviceTokenController = Get.put(
        GetDeviceTokenController());

    if (Platform.isWindows) {
      EasyLoading.showError("تسجيل الدخول باستخدام Google غير مدعوم على Windows.");
      return;
    }

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.authenticate(); // الطريقة الجديدة

      if (googleSignInAccount != null) {
        EasyLoading.show(status: "انتظر...");
        final GoogleSignInAuthentication googleSignInAuthentication =
            googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          UserModel userModel = UserModel(
            uId: user.uid,
            username: user.displayName ?? '',
            engName: '',
            userCode: '',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            userImg: user.photoURL ?? '',
            userDeviceToken:
                getDeviceTokenController.deviceToken ?? '',
            country: '',
            city: '',
            userAddress: '',
            street: '',
            isAdmin: false,
            isActive: true,
            createdOn: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('siteUsers')
              .doc(user.uid)
              .set(userModel.toMap());

          EasyLoading.dismiss();
          Get.offAll(() => UserNameAndPassword());
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('❌ error $e');
      if (e.toString().contains('[firebase_auth/user-disabled]')) {
        Get.snackbar(
          'حساب محظور',
          'عذراً، تم حظر هذا الحساب من قبل المسؤول',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ في تسجيل الدخول',
          'حدث خطأ أثناء تسجيل الدخول باستخدام Google',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }
}
