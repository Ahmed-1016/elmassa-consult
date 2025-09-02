import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ImportExcelPage extends StatefulWidget {
  const ImportExcelPage({super.key});

  @override
  State<ImportExcelPage> createState() => _ImportExcelPageState();
}

class _ImportExcelPageState extends State<ImportExcelPage> {
  final TextEditingController _passController = TextEditingController();
  bool checkBeforeInsert = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد بيانات Excel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'الرقم السري',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('التحقق من الطلبات'),
                Switch(
                  value: checkBeforeInsert,
                  onChanged: (val) {
                    setState(() {
                      checkBeforeInsert = val;
                    });
                  },
                ),
              ],
            ),
            ImportModeCard(
              title: checkBeforeInsert
                  ? 'الوضع: التحقق من الطلبات'
                  : 'الوضع: دمج مباشر بدون تحقق',
              description: checkBeforeInsert
                  ? 'سيتم إدخال الطلبات فقط إذا لم تكن موجودة مسبقًا'
                  : 'سيتم إدخال أو تحديث كل الطلبات حتى لو كانت موجودة',
              icon: checkBeforeInsert ? Icons.verified : Icons.upload_file,
              color: checkBeforeInsert ? Colors.blue : Colors.orange,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('بدء الاستيراد'),
              onPressed: () {
                _handleImport(
                  _passController.text.trim(),
                  checkBeforeInsert: checkBeforeInsert,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleImport(String password,
      {required bool checkBeforeInsert}) async {
    if (password != "massa14") {
      Get.snackbar(
        "خطأ",
        "الرقم السرى غير صحيح",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("لم يتم اختيار ملف"),
              backgroundColor: Colors.red),
        );
        return;
      }

      EasyLoading.show(status: "جارى قراءة بيانات شيت الاكسيل");

      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<String> insertedOrders = [];
      List<String> duplicateOrders = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        for (var row in sheet.rows.skip(1)) {
          List<String> rowValues = List.generate(19, (index) {
            if (index < row.length && row[index] != null) {
              return row[index]!.value.toString();
            }
            return '';
          });

          String orderNumber = rowValues[0];
          if (orderNumber.trim().isEmpty) continue;

          final docRef = FirebaseFirestore.instance
              .collection('elmassaConsult')
              .doc(rowValues[7])
              .collection('newOrders')
              .doc(orderNumber);

          if (checkBeforeInsert) {
            final docSnapshot = await docRef.get();
             if (docSnapshot.exists) {
      // تحقق من اختلاف team فقط، إذا كان مختلف نحدثه
      final existingTeam = docSnapshot.data()?['team']?.toString();
      if (existingTeam != rowValues[13] && rowValues[13].isNotEmpty) {
        await docRef.set({'team': rowValues[13]}, SetOptions(merge: true));
        debugPrint("🔄 تم تحديث team لطلب $orderNumber");
      }
      continue;
    }
          }

          Timestamp? distributionDate;
          if (rowValues[1].isNotEmpty) {
            try {
              distributionDate =
                  Timestamp.fromDate(DateTime.parse(rowValues[1]));
            } catch (_) {}
          }

          Timestamp? surveyingDate;
          if (rowValues[2].isNotEmpty) {
            try {
              surveyingDate =
                  Timestamp.fromDate(DateTime.parse(rowValues[2]));
            } catch (_) {}
          }

          await docRef.set({
            'orderNumber': orderNumber,
            'distributionDate': distributionDate,
            'surveyingDate': surveyingDate,
            'name': rowValues[3],
            'phoneNumber': rowValues[4],
            'unitType': rowValues[5],
            'areaM2': rowValues[6],
            'governorate': rowValues[7],
            'departmentOrCenter': rowValues[8],
            'sheikhdomOrVillage': rowValues[9],
            'unitNumber': rowValues[10],
            'streetName': rowValues[11],
            'distinctiveSigns': rowValues[12],
            'team': rowValues[13],
            'orderStatus': rowValues[14],
            'reasonForInability': rowValues[15],
            'reviewStatus': rowValues[16],
            'companyName': rowValues[17],
            'engName': rowValues[18],
          }, SetOptions(merge: true));

          insertedOrders.add(orderNumber);
        }
      }

      EasyLoading.dismiss();

      // 👇 الانتقال لصفحة التقرير بعد الانتهاء
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImportReportPage(
            insertedOrders: insertedOrders,
            duplicateOrders: duplicateOrders,
          ),
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء التحديث: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// ✅ ويدجت كارت لوصف الوضع الحالي
class ImportModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const ImportModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}

// ✅ صفحة التقرير بعد الاستيراد
class ImportReportPage extends StatelessWidget {
  final List<String> insertedOrders;
  final List<String> duplicateOrders;

  const ImportReportPage({
    super.key,
    required this.insertedOrders,
    required this.duplicateOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تقرير الاستيراد")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("✅ الطلبات المدخلة: ${insertedOrders.length}",
                style: const TextStyle(fontSize: 18, color: Colors.green)),
            if (insertedOrders.isNotEmpty)
              ...insertedOrders.map((e) => ListTile(
                    title: Text(e),
                    leading: const Icon(Icons.check, color: Colors.green),
                  )),

            const Divider(),

            Text("⛔ الطلبات المكررة: ${duplicateOrders.length}",
                style: const TextStyle(fontSize: 18, color: Colors.red)),
            if (duplicateOrders.isNotEmpty)
              ...duplicateOrders.map((e) => ListTile(
                    title: Text(e),
                    leading: const Icon(Icons.warning, color: Colors.red),
                  )),
          ],
        ),
      ),
    );
  }
}
