// ignore_for_file: avoid_unnecessary_containers, file_names, unnecessary_null_comparison

import 'dart:io' show Platform;

import 'package:ElMassaConsult/auth-panel/sign-up-screen.dart';
import 'package:ElMassaConsult/auth-panel/welcome-screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ElMassaConsult/controllers/sign-in-controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import '../../../controllers/get-user-data-controller.dart';
import 'forget-password-screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final SignInController signInController = Get.put(SignInController());
  final GetUserDataController getUserDataController =
      Get.put(GetUserDataController());
  final _formKey = GlobalKey<FormState>();
  TextEditingController useremail = TextEditingController();
  TextEditingController userpassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, iskeyboradvisible) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: AppConstant.appTextColor),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppConstant.appSecondaryColor,
              statusBarIconBrightness: Brightness.light),
          backgroundColor: AppConstant.appSecondaryColor,
          title: Text("تسجيل الدخول",
              style: TextStyle(
                  color: AppConstant.appTextColor,
                  fontSize: 25,
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  iskeyboradvisible
                      ? const Text(
                          "El Massa Consult",
                          style: TextStyle(
                              color: AppConstant.appSecondaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        )
                      : Column(
                          children: [
                            SizedBox(
                                width: 250,
                                height: 250,
                                child: Image.asset(
                                    'assets/images/elmassa_logo.png')),
                          ],
                        ),
                  SizedBox(height: Get.height / 20),
                  SizedBox(
                    width: Platform.isWindows ? Get.width / 2 : null,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: Get.width,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              controller: useremail,
                              cursorColor: AppConstant.appSecondaryColor,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: "البريد الالكترونى",
                                prefixIcon: const Icon(Icons.email),
                                contentPadding:
                                    const EdgeInsets.only(top: 2.0, left: 8.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'برجاء ادخال بريدك الالكترونى';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'برجاء ادخال بريد الكترونى صالح';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: Get.width,
                          child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Obx(
                                () => TextFormField(
                                  controller: userpassword,
                                  obscureText:
                                      signInController.isPasswordVisible.value,
                                  cursorColor: AppConstant.appSecondaryColor,
                                  keyboardType: TextInputType.visiblePassword,
                                  decoration: InputDecoration(
                                    hintText: "كلمة السر",
                                    prefixIcon: const Icon(Icons.password),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        signInController.isPasswordVisible
                                            .toggle();
                                      },
                                      child: Icon(signInController
                                              .isPasswordVisible.value
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                    ),
                                    contentPadding: const EdgeInsets.only(
                                        top: 2.0, left: 8.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'برجاء ادخال كلمة السر';
                                    }
                                    if (value.length < 8) {
                                      return 'لايمكن ان تقل كلمة السر عن 8 احرف او ارقام';
                                    }
                                    return null;
                                  },
                                ),
                              )),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () =>
                                Get.to(() => const ForgetPasswordScreen()),
                            child: const Text(
                              "نسيت كلمة السر؟",
                              style: TextStyle(
                                  color: AppConstant.appSecondaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: Get.height / 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              String email = useremail.text.trim();
                              String password = userpassword.text.trim();

                              if (email.isEmpty || password.isEmpty) {
                                Get.snackbar("خطأ", "برجاء ادخل جميع البيانات",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        AppConstant.appSecondaryColor,
                                    colorText: AppConstant.appTextColor);
                              } else {
                                UserCredential? userCredential =
                                    await signInController.signInMethod(
                                        email, password);

                                if (userCredential != null) {
                                  if (userCredential.user!.emailVerified) {
                                    var userData = await getUserDataController
                                        .getUserData(userCredential.user!.uid);

                                    if (userData[0]['isAdmin'] == false) {
                                      Get.offAll(() => const SiteGovScreen());
                                      Get.snackbar(
                                          "تنبيه", "!تم تسجيل الدخول بنجاح",
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor:
                                              AppConstant.appSecondaryColor,
                                          colorText: AppConstant.appTextColor);
                                    }
                                  } else {
                                    Get.snackbar(
                                      "تنبيه",
                                      "برجاء تفعيل بريدك الالكترونى",
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor:
                                          AppConstant.appSecondaryColor,
                                      colorText: AppConstant.appTextColor,
                                    );
                                  }
                                } else {
                                  Get.snackbar(
                                    "خطأ",
                                    "خطأ فى البريد الالكترونى او كلمة السر",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        AppConstant.appSecondaryColor,
                                    colorText: AppConstant.appTextColor,
                                  );
                                }
                              }
                            }
                          },
                          child: const Text(
                            "تسجيل الدخول",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        SizedBox(height: Get.height / 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "ليس لدى حساب؟ ",
                              style: TextStyle(color: Colors.blue),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 255, 25, 0)),
                              onPressed: () =>
                                  Get.offAll(() => const SignupScreen()),
                              child: const Text(
                                "تسجيل حساب جديد",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: Get.height / 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 51, 255)),
                          onPressed: () => Get.offAll(() => WelcomeScreen()),
                          child: const Text(
                            "سجل الدخول بطريقة اخرى",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
