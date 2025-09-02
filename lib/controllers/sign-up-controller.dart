// ignore_for_file: body_might_complete_normally_nullable, unused_import, file_names

import 'dart:math'; // استيراد مكتبة الرياضيات

import 'package:ElMassaConsult/models/user-model.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // استيراد مكتبة Firestore للتعامل مع قاعدة البيانات
import 'package:firebase_auth/firebase_auth.dart'; // استيراد مكتبة Firebase Authentication للتعامل مع تسجيل الدخول
import 'package:flutter_easyloading/flutter_easyloading.dart'; // استيراد مكتبة EasyLoading لعرض الرسائل التحميل
import 'package:get/get.dart'; // استيراد مكتبة GetX لإدارة الحالة

class SignUpController extends GetxController {
  // تعريف كلاس وحدة التحكم لتسجيل المستخدمين
  final FirebaseAuth _auth = FirebaseAuth.instance; // إنشاء كائن FirebaseAuth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // إنشاء كائن FirebaseFirestore

  //for password visibility
  var isPasswordVisible = true.obs; // تعريف متغير لمراقبة حالة رؤية كلمة المرور

  Future<UserCredential?> signUPMethod(
    // تعريف دالة لتسجيل المستخدمين
    String username, // اسم المستخدم
    String useremail, // البريد الإلكتروني للمستخدم
    String userphone, // رقم الهاتف للمستخدم
    String userCity, // مدينة المستخدم
    String userpassword, // كلمة مرور المستخدم
    String userDeviceToken, // رمز جهاز المستخدم
  ) async {
    try {
      EasyLoading.show(
          status: "please wait..."); // عرض رسالة "please wait..." أثناء التحميل
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: useremail, // تعيين البريد الإلكتروني
        password: userpassword, // تعيين كلمة المرور
      );
      //Send email verification
      await userCredential.user!
          .sendEmailVerification(); // إرسال بريد إلكتروني لتفعيل الحساب
      UserModel userModel = UserModel(
        uId: userCredential.user!.uid, // تعيين معرف المستخدم
        username: username, // تعيين اسم المستخدم
        engName: '', // تعيين اسم المستخدم
        userCode: '', // تعيين كود المستخدم
        email: useremail, // تعيين البريد الإلكتروني
        phone: userphone, // تعيين رقم الهاتف
        userImg: '', // تعيين صورة المستخدم
        userDeviceToken: userDeviceToken, // تعيين رمز جهاز المستخدم
        country: '', // تعيين البلد
        city: userCity, // تعيين المدينة
        userAddress: '', // تعيين عنوان المستخدم
        street: '', // تعيين الشارع
        isAdmin: false, // تعيين حالة المستخدم كمسؤول
        isActive: true, // تعيين حالة نشاط المستخدم
        createdOn: DateTime.now(), // تعيين تاريخ الإنشاء
      );

      //add user data to firestore
      await _firestore
          .collection('siteUsers') // الوصول إلى مجموعة المستخدمين في Firestore
          .doc(userCredential.user!.uid) // تعيين معرف الوثيقة
          .set(userModel.toMap()); // تخزين بيانات المستخدم في Firestore
      EasyLoading.dismiss(); // إخفاء رسالة التحميل
      return userCredential; // إرجاع بيانات المستخدم الذي تم تسجيله
    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء Firebase Authentication
      EasyLoading.dismiss(); // إخفاء رسالة التحميل في حالة حدوث خطأ
      Get.snackbar(
        'Error', // عنوان الرسالة
        "$e", // محتوى الرسالة
        snackPosition: SnackPosition.BOTTOM, // موضع الرسالة
        backgroundColor: AppConstant.appSecondaryColor, // لون خلفية الرسالة
        colorText: AppConstant.appTextColor, // لون نص الرسالة
      );
    }
  }
}
