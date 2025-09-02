// ignore_for_file: file_names

class UserModel {
  // تعريف كلاس نموذج بيانات المستخدم
  final String uId; // معرف المستخدم
  final String username; // اسم المستخدم
  final String engName; // اسم المستخدم
  final String userCode; // كود المستخدم
  final String email; // البريد الإلكتروني
  final String phone; // رقم الهاتف
  final String userImg; // صورة المستخدم
  final String userDeviceToken; // رمز جهاز المستخدم
  final String country; // البلد
  final String city; // المدينة
  final String userAddress; // عنوان المستخدم
  final String street; // الشارع
  final bool isAdmin; // حالة المستخدم كمسؤول
  final bool isActive; // حالة نشاط المستخدم
  final dynamic createdOn; // تاريخ الإنشاء

  UserModel({
    // البناء لإنشاء كائن UserModel
    required this.uId,
    required this.username,
    required this.engName,
    required this.userCode,
    required this.email,
    required this.phone,
    required this.userImg,
    required this.userDeviceToken,
    required this.country,
    required this.city,
    required this.userAddress,
    required this.street,
    required this.isAdmin,
    required this.isActive,
    required this.createdOn,
  });

  Map<String, dynamic> toMap() {
    // دالة لتحويل كائن UserModel إلى خريطة
    return {
      'uId': uId,
      'username': username,
      'engName': engName,
      'userCode': userCode,
      'email': email,
      'phone': phone,
      'userImg': userImg,
      'userDeviceToken': userDeviceToken,
      'country': country,
      'city': city,
      'userAddress': userAddress,
      'street': street,
      'isAdmin': isAdmin,
      'isActive': isActive,
      'createdOn': createdOn,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> json) {
    // دالة المصنع لتحويل خريطة إلى كائن UserModel
    return UserModel(
      uId: json['uId'],
      username: json['username'],
      engName: json['engName'],
      userCode: json['userCode'],
      email: json['email'],
      phone: json['phone'],
      userImg: json['userImg'],
      userDeviceToken: json['userDeviceToken'],
      country: json['country'],
      city: json['city'],
      userAddress: json['userAddress'],
      street: json['street'],
      isAdmin: json['isAdmin'],
      isActive: json['isActive'],
      createdOn: json['createdOn'].toString(),
    );
  }
}
