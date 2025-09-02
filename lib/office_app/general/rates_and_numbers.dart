// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class RatesAndNumbers extends StatelessWidget {
  final String? userName;

  const RatesAndNumbers({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('احصاءات الطلبات'),
        centerTitle: true,
      ),
      body: const StatusTable(),
    );
  }
}

class StatusTable extends StatefulWidget {
  const StatusTable({super.key});

  @override
  State<StatusTable> createState() => _StatusTableState();
}

class _StatusTableState extends State<StatusTable> {
  final List<String> governorates = [
    "محافظة أسوان",
    "محافظة الأقصر",
    "محافظة قنا",
    "محافظة سوهاج",
    "محافظة أسيوط",
    "محافظة القاهرة",
    "محافظة الجيزة",
    "محافظة الغربية",
    "محافظة المنيا",
  ];

  final List<String> orderStatuses = [
    "لم يتم الرفع",
    "تعذر الرفع",
"جارى الرسم",
    "Stage 1",
    "مرفوض مكتب فنى",
    "إعادة المعاينة",
    "Stage 2",
    "Stage 3",
    "شهادات مطلوب مراجعتها",
    "شهادات تمت مراجعتها",
    // "تم الارسال الى الإدارة",
  ];

  Map<String, Map<String, int>> statusCounts = {};
  bool isLoading = true;
  bool hasLoadedData = false;
  List<QueryDocumentSnapshot> teamWorkCodeDocuments = [];
  String? selectedTeamWorkCodeId;

  @override
  void initState() {
    super.initState();
    _loadFirestoreData().then((_) {
      // After loading team codes, load all data (no team filter)
      if (mounted) {
        _loadStatusCounts();
      }
    });
  }

  Future<void> _loadFirestoreData() async {
    try {
      final [teamWorkCodeResult] = await Future.wait([
        FirebaseFirestore.instance.collection('siteTeamWorkCodes').get(),
      ]);

      if (mounted) {
        setState(() {
          teamWorkCodeDocuments = teamWorkCodeResult.docs;
          isLoading = false;
        });
      }

    } catch (e) {
      setState(() {
        isLoading = false;
        hasLoadedData = true;
      });
      Get.snackbar(
        "خطأ",
        "فشل في تحميل البيانات",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

Future<void> _loadStatusCounts() async {
  setState(() => isLoading = true);
  try {
    statusCounts.clear();

    await Future.wait(governorates.map((gov) async {
      Query query = FirebaseFirestore.instance
          .collection('elmassaConsult')
          .doc(gov)
          .collection('newOrders');

      // إضافة فلتر الفريق (لو متحدد)
      if (selectedTeamWorkCodeId != null) {
        query = query.where('team', isEqualTo: selectedTeamWorkCodeId);
      }

      final snapshot = await query.get();

      // حساب كل حالة في الكود بدلاً من كويري منفصل
      statusCounts[gov] = {};
      for (var doc in snapshot.docs) {
        final status = doc['orderStatus'] ?? '';
        if (orderStatuses.contains(status)) {
          statusCounts[gov]![status] = (statusCounts[gov]![status] ?? 0) + 1;
        }
      }

      // لو في حالة مش موجودة في المحافظة دي، نخليها صفر
      for (var status in orderStatuses) {
        statusCounts[gov]![status] = statusCounts[gov]![status] ?? 0;
      }
    }));

    setState(() {
      isLoading = false;
      hasLoadedData = true;
    });
  } catch (e) {
    Get.snackbar(
      "خطأ",
      "فشل في تحميل البيانات: $e",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    setState(() {
      isLoading = false;
      hasLoadedData = true;
    });
  }
}

 Widget _buildDropdown({
    required String label,
    required List<QueryDocumentSnapshot> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    // Create a new list with 'All Teams' as the first option
    final allItems = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text(
          'عرض الكل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      ...items.map((doc) => DropdownMenuItem<String>(
        value: doc.id,
        child: Text(
          doc.id,
          style: const TextStyle(fontSize: 16),
        ),
      )).toList(),
    ];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: allItems,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // القائمة المنسدلة لاختيار الفريق
       Padding(
  padding: const EdgeInsets.all(16.0),
  child: teamWorkCodeDocuments.isEmpty
      ? const Text("لا توجد بيانات متاحة")
      : _buildDropdown(
          label: "برجاء اختيار الكود",
          items: teamWorkCodeDocuments,
          value: selectedTeamWorkCodeId,
          onChanged: (value) async {
            if (value != null) {
              setState(() {
                selectedTeamWorkCodeId = value;
                hasLoadedData = false;
                isLoading = true;
              });
              await _loadStatusCounts();
            }
          },
        ),
),

        if (isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDataTable(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (!hasLoadedData) {
      return const Center(child: Text('جاري تحميل البيانات...'));
    }
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        dividerThickness: 2,
        columnSpacing: 16,
        horizontalMargin: 12,
        columns: [
          const DataColumn(
            label: Center(
              child: Text('المحافظة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ...orderStatuses.map(
            (status) => DataColumn(
              label: Center(
                child: Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const DataColumn(
            label: Center(
              child: Text('الاجمالي',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        rows: [
          ...governorates.map(
            (gov) => DataRow(
              cells: [
                DataCell(Center(child: Text(gov))),
                ...orderStatuses.map(
                  (status) => DataCell(
                    Center(
                      child: Text(
                        '${statusCounts[gov]?[status] ?? 0}',
                        style: TextStyle(
                          color: (statusCounts[gov]?[status] ?? 0) > 0
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      '${_calculateRowTotal(gov)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DataRow(
            color: MaterialStateProperty.all(Colors.grey[200]),
            cells: [
              const DataCell(
                Center(
                  child: Text('الاجمالي',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              ...orderStatuses.map(
                (status) => DataCell(
                  Center(
                    child: Text(
                      '${_calculateColumnTotal(status)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    '${_calculateGrandTotal()}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateRowTotal(String gov) {
    int total = 0;
    for (String status in orderStatuses) {
      total += statusCounts[gov]?[status] ?? 0;
    }
    return total;
  }

  int _calculateColumnTotal(String status) {
    int total = 0;
    for (String gov in governorates) {
      total += statusCounts[gov]?[status] ?? 0;
    }
    return total;
  }

  int _calculateGrandTotal() {
    int total = 0;
    for (String gov in governorates) {
      total += _calculateRowTotal(gov);
    }
    return total;
  }
}
