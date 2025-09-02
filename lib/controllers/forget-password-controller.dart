// ignore_for_file: non_constant_identifier_names, file_names, unused_field

import 'package:ElMassaConsult/auth-panel/sign-in-screen.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // استيراد مكتبة Firestore للتعامل مع قاعدة البيانات
import 'package:firebase_auth/firebase_auth.dart'; // استيراد مكتبة Firebase Authentication للتعامل مع تسجيل الدخول
import 'package:flutter_easyloading/flutter_easyloading.dart'; // استيراد مكتبة EasyLoading لعرض الرسائل التحميل
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة

class ForgertPasswordController extends GetxController {
  // تعريف كلاس وحدة التحكم لنسيان كلمة المرور
  final FirebaseAuth _auth = FirebaseAuth.instance; // إنشاء كائن FirebaseAuth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // إنشاء كائن FirebaseFirestore

  Future<void> ForgetPasswordMethod(
    // تعريف دالة لنسيان كلمة المرور
    String userEmail, // البريد الإلكتروني للمستخدم
  ) async {
    try {
      EasyLoading.show(
          status: "Please wait"); // عرض رسالة "Please wait" أثناء التحميل

      await _auth.sendPasswordResetEmail(
          email: userEmail); // إرسال بريد إلكتروني لإعادة تعيين كلمة المرور

      Get.snackbar(
        "Request Sent Sucessfully", // عنوان الرسالة
        "Password Reset link sent to $userEmail", // محتوى الرسالة
        snackPosition: SnackPosition.BOTTOM, // موضع الرسالة
        backgroundColor: AppConstant.appSecondaryColor, // لون خلفية الرسالة
        colorText: AppConstant.appTextColor, // لون نص الرسالة
      );

      Get.offAll(() => const SigninScreen()); // الانتقال إلى شاشة تسجيل الدخول

      EasyLoading.dismiss(); // إخفاء رسالة التحميل
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء Firebase Authentication
      EasyLoading.dismiss(); // إخفاء رسالة التحميل في حالة حدوث خطأ
      Get.snackbar(
        "Error", // عنوان الرسالة
        "$e", // محتوى الرسالة
        snackPosition: SnackPosition.BOTTOM, // موضع الرسالة
        backgroundColor: AppConstant.appSecondaryColor, // لون خلفية الرسالة
        colorText: AppConstant.appTextColor, // لون نص الرسالة
      );
    }
  }
}
