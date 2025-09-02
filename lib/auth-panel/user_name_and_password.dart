import 'dart:io';

import 'package:ElMassaConsult/models/site_team_work_model.dart';
import 'package:ElMassaConsult/office_app/general/admin_screen.dart';
import 'package:ElMassaConsult/office_app/general/admin_screen_windows.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen_windows.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserNameAndPassword extends StatefulWidget {
  const UserNameAndPassword({super.key});

  @override
  State<UserNameAndPassword> createState() => _UserNameAndPasswordState();
}

class _UserNameAndPasswordState extends State<UserNameAndPassword> {
  List<SiteTeamWorkModel> teamWorkModelList = [];
  // bool isLoading = true;
  String? selectedCategory;
  String? selectedUsername;
  String? enteredPassword = '';

  @override
  void initState() {
    super.initState();

    _loadFirestoreData();
  }

  Future<void> _storeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCategory', selectedCategory ?? '');
    await prefs.setString('selectedUsername', selectedUsername ?? '');
    await prefs.setString('enteredPassword', enteredPassword ?? '');
  }

  Future<void> _loadFirestoreData() async {
    if (selectedCategory == null) return; // تأكد من أن الفئة محددة

    try {
      final collectionName =
          selectedCategory == "موقع" ? 'siteTeamWork' : 'officeTeamWork';

      final teamWorkResult =
          await FirebaseFirestore.instance.collection(collectionName).get();

      setState(() {
        teamWorkModelList = teamWorkResult.docs.map((doc) {
          return SiteTeamWorkModel.fromMap(doc.data());
        }).toList();
      });
    } catch (e) {
      Get.snackbar(
        "خطأ",
        "فشل في تحميل البيانات",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleSubmit() async {
    if (selectedUsername != null && enteredPassword!.isNotEmpty) {
      final selectedTeamWork = teamWorkModelList.firstWhere(
        (teamWork) => teamWork.username == selectedUsername,
        orElse: () => SiteTeamWorkModel(
          username: '',
          password: '',
          createdOn: DateTime.now(),
        ),
      );

      if (selectedTeamWork.password == enteredPassword) {
        await _storeCredentials(); // Store credentials locally
        if (selectedCategory == "موقع") {
          if (!kIsWeb && Platform.isAndroid) {
            Get.offAll(() => SiteGovScreen(
                userName: selectedUsername,
                selectedCategory: selectedCategory));
          } else {
            Get.offAll(() => SiteGovScreenWindows(userName: selectedUsername));
          }
        } else {
          if (!kIsWeb && Platform.isAndroid) {
            if (selectedUsername == "Admin") {
              Get.offAll(() => AdminScreen(
                  userName: selectedUsername!,
                  selectedCategory: selectedCategory!));
            } else {
              Get.offAll(() => OfficeGovScreen(
                  userName: selectedUsername!,
                  selectedCategory: selectedCategory!));
            }
          } else {
            if (selectedUsername == "Admin") {
              Get.offAll(() => AdminScreenWindows(userName: selectedUsername));
            } else {
              Get.offAll(
                  () => OfficeGovScreenWindows(userName: selectedUsername));
            }
          }
        }
      } else {
        Get.snackbar(
          "خطأ",
          "الرقم السري غير صحيح",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        "خطأ",
        "برجاء اختيار الاسم وإدخال الرقم السري",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Photo.png'),
          fit: BoxFit.cover,
        
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          title: const Text("ادخل البيانات المطلوبة",style: TextStyle(color: Colors.red,fontSize: 25,fontWeight: FontWeight.bold),),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body:
            Column(
              
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: SizedBox(
                      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        _buildDropdown(
                          label: "برجاء اختيار التخصص",
                          items: ["موقع", "مكتب فنى"],
                          value: selectedCategory,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                              selectedUsername =
                                  null; // مسح اسم المستخدم عند تغيير التخصص
                              _loadFirestoreData(); // إعادة تحميل البيانات بناءً على الاختيار
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                  
                        // اختيار الاسم
                        if (selectedCategory != null)
                          _buildDropdown(
                            label: "برجاء اختيار الاسم",
                            items: teamWorkModelList.isEmpty
                                ? [] // Return an empty list when no data
                                : teamWorkModelList,
                            value: selectedUsername,
                            onChanged: (value) {
                              setState(() {
                                selectedUsername = value;
                              });
                            },
                          ),
                        const SizedBox(height: 20),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "الرقم السري",
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          controller:
                              TextEditingController(text: enteredPassword),
                          onChanged: (value) {
                            enteredPassword = value;
                          },
                          onSubmitted: (_) {
                            _handleSubmit(); // تأكيد البيانات عند الضغط على Enter
                          },
                        ),]
                      ),
                    ),
                  ),),
                ),
              ],
            ),
          ),
      
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<dynamic> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item is SiteTeamWorkModel ? item.username : item,
          child: Text(
            item is SiteTeamWorkModel ? item.username : item,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
