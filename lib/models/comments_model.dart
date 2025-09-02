// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModel {
  final String orderNumber;
  final String username;
  final String usercode;
  final String comments;
  final DateTime createdOn;

  CommentsModel({
    required this.orderNumber,
    required this.username,
    required this.usercode,
    required this.comments,
    required this.createdOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'username': username,
      'usercode': usercode,
      'comments': comments,
      'createdOn': createdOn,
    };
  }

  factory CommentsModel.fromMap(Map<String, dynamic> json) {
    return CommentsModel(
      orderNumber: json['orderNumber'],
      username: json['username'],
      usercode: json['usercode'],
      comments: json['comments'],
      createdOn: (json['createdOn'] as Timestamp).toDate(),
    );
  }
}
