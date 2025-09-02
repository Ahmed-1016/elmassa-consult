import 'dart:io';

import 'package:ElMassaConsult/services/notifications/notif.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfficeOrderWatcher {
  late SharedPreferences prefs;
  String? myUserCode;
  String? govName;

  int previousCount = 0;

  void init(BuildContext context) {
    _initPrefs(context);
    print('[OfficeOrderWatcher] init called');
  }

  Future<void> _initPrefs(BuildContext context) async {
    prefs = await SharedPreferences.getInstance();
    myUserCode = prefs.getString('userCode');
    govName = prefs.getString('govName');

    print('userCode: $myUserCode');
    print('govName: $govName');

    if (myUserCode != null && govName != null) {
      _newOrderAdded(context);
      _regectedOrders(context);
      _rescanOrders(context);
      _certificatesToReview(context);
    }
  }
void _showPlatformNotification( {
  required int id,
  required String title,
  required String body,
}) {
  if (Platform.isWindows) {
    // عرض SnackBar بدل الإشعار
   Get.snackbar(
  title, // العنوان
  body, // النص
  snackPosition: SnackPosition.BOTTOM, // مكان الظهور (TOP أو BOTTOM)
  backgroundColor: Colors.red,
  colorText: Colors.white,
);

  } else {
    // عرض الإشعار العادي
    PushNotificationsMix.showNotification(
      id: id,
      title: title,
      body: body,
    );
  }
}
  int _newPreviousCount = 0;
  int _newCurrentCount = 0;
  int _newDifference = 0;
  void _newOrderAdded(BuildContext context) {
    FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(govName)
        .collection('newOrders')
        .where('orderStatus', isEqualTo: 'Stage 1')
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['orderStatus'] == myUserCode;
      }).toList();

      _newCurrentCount = docs.length;

      print('عدد الطلبات الجديدة: $_newCurrentCount');

      if (_newCurrentCount > _newPreviousCount) {
        _newDifference = _newCurrentCount - _newPreviousCount;
        Future.delayed(const Duration(seconds: 1), () {
          _showPlatformNotification(
            id: 1,
            title: 'طلبات جديدة!',
            body:
                '$_newDifference طلب جديد في $govName. الإجمالي الآن: $_newCurrentCount',
          );
        });
      }

      _newPreviousCount = _newCurrentCount;
    });
  }

  int _rejectedPreviousCount = 0;
  int _rejectedCurrentCount = 0;
  int _rejectedDifference = 0;

  void _regectedOrders(BuildContext context) {
    FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(govName)
        .collection('newOrders')
        .where('orderStatus', isEqualTo: 'مرفوض مكتب فنى')
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['team'] == myUserCode || data['orderStatus'] == myUserCode;
      }).toList();

      _rejectedCurrentCount = docs.length;
      print('عدد الطلبات المرفوضة: $_rejectedCurrentCount');

      if (_rejectedCurrentCount > _rejectedPreviousCount) {
        _rejectedDifference = _rejectedCurrentCount - _rejectedPreviousCount;

        Future.delayed(const Duration(seconds: 2), () {
          _showPlatformNotification(
            id: 2,
            title: 'طلبات مرفوضة!',
            body:
                '$_rejectedDifference طلب مرفوض في $govName. الإجمالي الآن: $_rejectedCurrentCount',
          );
        });
      }

      _rejectedPreviousCount = _rejectedCurrentCount;
    });
  }

  int _rescanPreviousCount = 0;
  int _rescanCurrentCount = 0;
  int _rescanDifference = 0;

  void _rescanOrders(BuildContext context) {
    FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(govName)
        .collection('newOrders')
        .where('orderStatus', isEqualTo: 'إعادة المعاينة')
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['team'] == myUserCode || data['orderStatus'] == myUserCode;
      }).toList();

      _rescanCurrentCount = docs.length;
      print('عدد الطلبات إعادة المعاينة: $_rescanCurrentCount');

      if (_rescanCurrentCount > _rescanPreviousCount) {
        _rescanDifference = _rescanCurrentCount - _rescanPreviousCount;

        Future.delayed(const Duration(seconds: 3), () {
          _showPlatformNotification(
            id: 3,
            title: 'طلبات إعادة المعاينة!',
            body:
                '$_rescanDifference طلب إعادة المعاينة في $govName. الإجمالي الآن: $_rescanCurrentCount',
          );
        });
      }

      _rescanPreviousCount = _rescanCurrentCount;
    });
  }

  int _reviewPreviousCount = 0;
  int _reviewCurrentCount = 0;
  int _reviewDifference = 0;

  void _certificatesToReview(BuildContext context) {
    FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(govName)
        .collection('newOrders')
        .where('orderStatus', isEqualTo: "شهادات مطلوب مراجعتها")
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['team'] == myUserCode || data['orderStatus'] == myUserCode;
      }).toList();

      _reviewCurrentCount = docs.length;
      print('عدد الشهادات المطلوب مراجعتها: $_reviewCurrentCount');

      if (_reviewCurrentCount > _reviewPreviousCount) {
        _reviewDifference = _reviewCurrentCount - _reviewPreviousCount;

        Future.delayed(const Duration(seconds: 4), () {
          _showPlatformNotification(
            id: 4,
            title: 'شهادات للمراجعة!',
            body:
                '$_reviewDifference شهادة جديدة للمراجعة في $govName. الإجمالي الآن: $_reviewCurrentCount',
          );
        });
      }

      _reviewPreviousCount = _reviewCurrentCount;
    });
  }
}