// ignore_for_file: unused_field, body_might_complete_normally_nullable, file_names

import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class SignInController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //for password visibility
  var isPasswordVisible = true.obs;

  Future<UserCredential?> signInMethod(
    String useremail,
    String userpassword,
  ) async {
    try {
      EasyLoading.show(status: "please wait...");
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: useremail,
        password: userpassword,
      );

      EasyLoading.dismiss();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Error',
        e.message.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstant.appSecondaryColor,
        colorText: AppConstant.appTextColor,
      );
    }
  }
}
