// ignore_for_file: file_names

class SiteTeamWorkModel {
  final String username;
  final String password;
  final dynamic createdOn;

  SiteTeamWorkModel({
    required this.username,
    required this.password,
    required this.createdOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'createdOn': createdOn,
    };
  }

  factory SiteTeamWorkModel.fromMap(Map<String, dynamic> json) {
    return SiteTeamWorkModel(
      username: json['username'],
      password: json['password'],
      createdOn: json['createdOn'],
    );
  }
}
