// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:excel/excel.dart' as excel;

typedef CellValue = excel.CellValue;
enum ResultType { done, error, notFound, notSupported }

class ExcelExportScreen extends StatefulWidget {
  final String? initialGovName;

  const ExcelExportScreen({
    Key? key,
    this.initialGovName,
  }) : super(key: key);

  @override
  State<ExcelExportScreen> createState() => _ExcelExportScreenState();
}

class _ExcelExportScreenState extends State<ExcelExportScreen> {
  bool _isLoading = false;
  String? _selectedGovName;
  final List<String> _governorates = [
    'محافظة أسوان',
    'محافظة الأقصر',
    'محافظة قنا',
    'محافظة سوهاج',
    'محافظة أسيوط',
    'محافظة القاهرة',
    'محافظة الجيزة',
    'محافظة الغربية',
    'محافظة المنيا',
  ];

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedGovName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار المحافظة أولاً')),
        );
        return;
      }

      // Get orders from Firebase for the selected governorate
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('elmassaConsult')
          .doc(_selectedGovName)
          .collection('newOrders')
          .get();

      // Create Excel file
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add headers
      List<String> headers = [
        'رقم الطلب',
        'تاريخ التوزيع',
        'تاريخ المسح',
        'الاسم',
        'رقم الهاتف',
        'نوع الوحدة',
        'المساحة',
        'المحافظة',
        'القسم/المركز',
        'الشيخة/القرية',
        'رقم الوحدة',
        'اسم الشارع',
        'العلامات المميزة',
        'الفريق',
        'حالة الطلب',
        'سبب عدم القدرة',
        'حالة المراجعة',
        'اسم الشركة',
        'اسم المهندس'
      ];

      // Add headers to Excel in row 1
      for (var i = 0; i < headers.length; i++) {
        sheetObject.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')).value = TextCellValue(headers[i]);
      }

      // Add data rows
      int rowIndex = 2;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        sheetObject.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(data['orderNumber'].toString());
        // Store dates in ISO 8601 format (YYYY-MM-DDTHH:MM:SS.ssssssZ)
        sheetObject.cell(CellIndex.indexByString('B$rowIndex')).value = TextCellValue(data['distributionDate'].toDate().toIso8601String());
        sheetObject.cell(CellIndex.indexByString('C$rowIndex')).value = TextCellValue(data['surveyingDate'].toDate().toIso8601String());
        sheetObject.cell(CellIndex.indexByString('D$rowIndex')).value = TextCellValue(data['name']);
        sheetObject.cell(CellIndex.indexByString('E$rowIndex')).value = TextCellValue(data['phoneNumber']);
        sheetObject.cell(CellIndex.indexByString('F$rowIndex')).value = TextCellValue(data['unitType']);
        sheetObject.cell(CellIndex.indexByString('G$rowIndex')).value = TextCellValue(data['areaM2']);
        sheetObject.cell(CellIndex.indexByString('H$rowIndex')).value = TextCellValue(data['governorate']);
        sheetObject.cell(CellIndex.indexByString('I$rowIndex')).value = TextCellValue(data['departmentOrCenter']);
        sheetObject.cell(CellIndex.indexByString('J$rowIndex')).value = TextCellValue(data['sheikhdomOrVillage']);
        sheetObject.cell(CellIndex.indexByString('K$rowIndex')).value = TextCellValue(data['unitNumber']);
        sheetObject.cell(CellIndex.indexByString('L$rowIndex')).value = TextCellValue(data['streetName']);
        sheetObject.cell(CellIndex.indexByString('M$rowIndex')).value = TextCellValue(data['distinctiveSigns']);
        sheetObject.cell(CellIndex.indexByString('N$rowIndex')).value = TextCellValue(data['team']);
        sheetObject.cell(CellIndex.indexByString('O$rowIndex')).value = TextCellValue(data['orderStatus']);
        sheetObject.cell(CellIndex.indexByString('P$rowIndex')).value = TextCellValue(data['reasonForInability']);
        sheetObject.cell(CellIndex.indexByString('Q$rowIndex')).value = TextCellValue(data['reviewStatus']);
        sheetObject.cell(CellIndex.indexByString('R$rowIndex')).value = TextCellValue(data['companyName']);
        sheetObject.cell(CellIndex.indexByString('S$rowIndex')).value = TextCellValue(data['engName']);
        rowIndex++;
      }

      // Save to file with sequential numbering if needed
      final directory = await getApplicationDocumentsDirectory();
      String baseFileName = 'orders_export';
      String extension = '.xlsx';
      int counter = 0;
      File file;
      
      // Check if file exists and add counter if needed
      do {
        counter++;
        String fileName = counter == 1 ? '$baseFileName$extension' : '${baseFileName}_$counter$extension';
        file = File('${directory.path}/$fileName');
      } while (await file.exists());

      await file.writeAsBytes(excel.encode()!);

      // Open file
      final filePath = file.path;
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير البيانات بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('**تم تصدير البيانات بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تصدير البيانات: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedGovName = widget.initialGovName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصدير البيانات إلى Excel'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'اختر المحافظة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Center(child: SizedBox(height: 10)),
            SizedBox(width: Get.width / 1.2,
              child: DropdownButton<String>(
                value: _selectedGovName,
                isExpanded: true,
                hint: const Text('اختر المحافظة'),
                items: _governorates.map((String governorate) {
                  return DropdownMenuItem<String>(
                    value: governorate,
                    child: Text(governorate),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGovName = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading || _selectedGovName == null ? null : _exportToExcel,
              icon: const Icon(Icons.download),
              label: const Text('تصدير البيانات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
