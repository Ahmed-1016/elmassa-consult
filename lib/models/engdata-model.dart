// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class EngData {
  final String orderNumber;
  final String username;
  final String usercode;
  final String orderStatus;
  final DateTime createdOn;

  EngData({
    required this.orderNumber,
    required this.username,
    required this.usercode,
    required this.orderStatus,
    required this.createdOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'username': username,
      'usercode': usercode,
      'orderStatus': orderStatus,
      'createdOn': createdOn,
    };
  }

  factory EngData.fromMap(Map<String, dynamic> json) {
    return EngData(
      orderNumber: json['orderNumber'],
      username: json['username'],
      usercode: json['usercode'],
      orderStatus: json['orderStatus'],
      createdOn: (json['createdOn'] as Timestamp).toDate(),
    );
  }
}