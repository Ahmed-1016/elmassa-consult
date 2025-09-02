// ignore_for_file: file_names, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class GetUserDataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> getUserData(String uId) async {
    // try {
    //   if (uId.isEmpty) {
    //     throw Exception("User ID is empty!");
    //   }

    final QuerySnapshot userData = await _firestore
        .collection('siteUsers')
        .where("uId", isEqualTo: uId)
        .get();

    return userData.docs;
    //   } catch (e) {
    //     print("Error fetching user data: $e");
    //     rethrow;
    //   }
  }
}
