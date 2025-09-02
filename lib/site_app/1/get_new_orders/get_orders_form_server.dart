// // order_uploader.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';

// class OrderUploader {
//   final String selectedGov;
//   final String surveyTeamId;
//   final int pageSize;

//   final HttpClient _httpClient = HttpClient()
//     ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);

//   OrderUploader({
//     required this.selectedGov,
//     required this.surveyTeamId,
//     this.pageSize = 20,
//   });

//   Future<String> fetchAndUploadAllPages() async {
//     int currentPage = 1;
//     List<Map<String, dynamic>> allFields = [];
//     int? totalRowCount;

//     try {
//       while (true) {
//         final headers = {
//           'accept': 'application/json, text/javascript, */*; q=0.01',
//           'accept-language': 'en-US,en;q=0.9',
//           'content-type': 'application/json; charset=UTF-8',
//           'origin': 'https://rscapps.edge-pro.com',
//           'referer': 'https://rscapps.edge-pro.com/Workflows/List?workflow=surveyteams',
//           'user-agent': 'Mozilla/5.0',
//           'x-requested-with': 'XMLHttpRequest',
//         };

//         final params = {
//           'workflow': 'surveyteams',
//           'lang': 'en-US',
//           'sessionid': 'f11195e0-eb00-4783-8d7d-435b2ff2b82a',
//           'tenant': 'rsc_v2',
//           'nodeid': 'assigned_tasks_surv',
//         };

//         final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/List/PageData')
//             .replace(queryParameters: params);

//         final request = await _httpClient.postUrl(url);
//         headers.forEach((key, value) => request.headers.set(key, value));

//         final requestBody = {
//           "PageState": {
//             "take": pageSize,
//             "skip": (currentPage - 1) * pageSize,
//             "page": currentPage,
//             "pageSize": pageSize,
//             "sort": []
//           },
//           "PredefinedFilter": "assigned",
//           "FilterValues": {
//             "gov": selectedGov,
//             "survey_team_id": surveyTeamId,
//             "collected": "0"
//           }
//         };

//         request.write(jsonEncode(requestBody));
//         final response = await request.close();
//         final responseBody = await response.transform(utf8.decoder).join();

//         if (response.statusCode == 200) {
//           final jsonData = jsonDecode(responseBody);
//           final dataMap = jsonData['data'] as Map<String, dynamic>;

//           totalRowCount ??= dataMap['totalrowcount'] as int;

//           if (dataMap['rows'] is List) {
//             final rows = dataMap['rows'] as List;
//             for (var record in rows) {
//               if (record['fields'] is Map<String, dynamic>) {
//                 allFields.add(record['fields'] as Map<String, dynamic>);
//               }
//             }
//           }

//           final totalPages = (totalRowCount / pageSize).ceil();
//           if (currentPage >= totalPages) break;

//           currentPage++;
//         } else {
//           throw Exception('HTTP Error: ${response.statusCode}');
//         }
//       }

//       final uploaded = await _uploadToFirebase(allFields);
//       return '✅ تم اضافة $uploaded طلب جديد بنجاح';

//     } catch (e) {
//       return '❌ خطأ أثناء التحميل او المنظومة لا تعمل: $e';
//     } finally {
//       _httpClient.close();
//     }
//   }

//  Future<int> _uploadToFirebase(List<Map<String, dynamic>> orders) async {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   int insertedCount = 0;

//   for (final order in orders) {
//     final String orderNumber = order['requestnumber']?.toString().trim() ?? '';
//     if (orderNumber.isEmpty) continue;

//     final docRef = firestore
//         .collection('elmassaConsult')
//         .doc(order['gov'])
//         .collection('newOrders')
//         .doc(orderNumber);

//     final docSnapshot = await docRef.get();

//     final String newTeam = order['survey_team_id']?.toString() ?? '';

//     if (docSnapshot.exists) {
//       // تحقق من اختلاف team فقط، إذا كان مختلف نحدثه
//       final existingTeam = docSnapshot.data()?['team']?.toString();
//       if (existingTeam != newTeam && newTeam.isNotEmpty) {
//         await docRef.set({'team': newTeam}, SetOptions(merge: true));
//         debugPrint("🔄 تم تحديث team لطلب $orderNumber");
//       }
//       continue;
//     }

//     // إذا لم يكن موجودًا، أضف الطلب كاملًا
//     Timestamp? assignmentDate;
//     if ((order['assignment_date_time'] ?? '').toString().isNotEmpty) {
//       assignmentDate = Timestamp.fromDate(
//         DateTime.parse(order['assignment_date_time']),
//       );
//     }

//     Timestamp? dueDate;
//     if ((order['due_date'] ?? '').toString().isNotEmpty) {
//       dueDate = Timestamp.fromDate(
//         DateTime.parse(order['due_date']),
//       );
//     }

//     await docRef.set({
//       'orderNumber': orderNumber,
//       'distributionDate': assignmentDate,
//       'surveyingDate': dueDate,
//       'name': order['arabicfullname'] ?? '',
//       'phoneNumber': order['telephonenumber'] ?? '',
//       'unitType': order['unitname'] ?? '',
//       'areaM2': order['area'] ?? '',
//       'governorate': order['gov'] ?? '',
//       'departmentOrCenter': order['sec'] ?? '',
//       'sheikhdomOrVillage': order['ssec'] ?? '',
//       'unitNumber': order['property_number'] ?? '',
//       'streetName': order['streetname'] ?? '',
//       'distinctiveSigns': order['unique_mark'] ?? '',
//       'team': newTeam,
//       'orderStatus': order['collected'] ?? '',
//       'reasonForInability': order['refuse_reason'] ?? '',
//       'reviewStatus': order['survey_review_status'] ?? '',
//       'companyName': order['companyname'] ?? '',
//       'engName': '',
//     }, SetOptions(merge: true));

//     insertedCount++;
//   }

//   return insertedCount;
// }

// }
