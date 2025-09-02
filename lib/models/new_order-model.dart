// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class NewOrderModel {
  final String orderNumber; // المفتاح الأساسي
  final DateTime distributionDate;
  final DateTime surveyingDate;
  final String name;
  final String phoneNumber;
  final String unitType;
  final String areaM2;
  final String governorate;
  final String departmentOrCenter;
  final String sheikhdomOrVillage;
  final String unitNumber;
  final String streetName;
  final String distinctiveSigns;
  final String team;
  final String orderStatus;
  final String reasonForInability;
  final String reviewStatus;
  final String companyName;
  final String engName;
  final DateTime? dueDate; // حقل جديد (اختياري)

  NewOrderModel({
    required this.orderNumber,
    required this.distributionDate,
    required this.surveyingDate,
    required this.name,
    required this.phoneNumber,
    required this.unitType,
    required this.areaM2,
    required this.governorate,
    required this.departmentOrCenter,
    required this.sheikhdomOrVillage,
    required this.unitNumber,
    required this.streetName,
    required this.distinctiveSigns,
    required this.team,
    required this.orderStatus,
    required this.reasonForInability,
    required this.reviewStatus,
    required this.companyName,
    required this.engName,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'distributionDate': distributionDate,
      'surveyingDate': surveyingDate,
      'name': name,
      'phoneNumber': phoneNumber,
      'unitType': unitType,
      'areaM2': areaM2,
      'governorate': governorate,
      'departmentOrCenter': departmentOrCenter,
      'sheikhdomOrVillage': sheikhdomOrVillage,
      'unitNumber': unitNumber,
      'streetName': streetName,
      'distinctiveSigns': distinctiveSigns,
      'team': team,
      'orderStatus': orderStatus,
      'reasonForInability': reasonForInability,
      'reviewStatus': reviewStatus,
      'companyName': companyName,
      'engName': engName,
      'dueDate': dueDate, // Firestore هيخزنها كـ Timestamp
    };
  }

  factory NewOrderModel.fromMap(Map<String, dynamic> json) {
    return NewOrderModel(
      orderNumber: json['orderNumber'] ?? '',
      distributionDate: (json['distributionDate'] as Timestamp).toDate(),
      surveyingDate: (json['surveyingDate'] as Timestamp).toDate(),
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      unitType: json['unitType'] ?? '',
      areaM2: json['areaM2'] ?? '',
      governorate: json['governorate'] ?? '',
      departmentOrCenter: json['departmentOrCenter'] ?? '',
      sheikhdomOrVillage: json['sheikhdomOrVillage'] ?? '',
      unitNumber: json['unitNumber'] ?? '',
      streetName: json['streetName'] ?? '',
      distinctiveSigns: json['distinctiveSigns'] ?? '',
      team: json['team'] ?? '',
      orderStatus: json['orderStatus'] ?? '',
      reasonForInability: json['reasonForInability'] ?? '',
      reviewStatus: json['reviewStatus'] ?? '',
      companyName: json['companyName'] ?? '',
      engName: json['engName'] ?? '',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] as Timestamp).toDate()
          : null,
    );
  }
}
