// ignore_for_file: file_names, non_constant_userIdentifier_names, non_constant_identifier_names

class QrCodeSignInModel {
  final String userId;
  final String userName;
  final String status;
  final dynamic expiresAt;
  final String typeApp;
  final String selectedCategory;

  QrCodeSignInModel({
    required this.userId,
    required this.userName,
    required this.status,
    required this.expiresAt,
    required this.typeApp,
    required this.selectedCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'status': status,
      'expiresAt': expiresAt,
      'typeApp': typeApp,
      'selectedCategory': selectedCategory,
    };
  }

  factory QrCodeSignInModel.fromMap(Map<String, dynamic> json) {
    return QrCodeSignInModel(
      userId: json['userId'],
      userName: json['userName'],
      status: json['status'],
      expiresAt: json['expiresAt'].toString(),
      typeApp: json['typeApp'],
      selectedCategory: json['selectedCategory'],
    );
  }
}
