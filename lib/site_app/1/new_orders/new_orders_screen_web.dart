// new_orders_screen_web.dart
// هذا الملف يحتوي على الكود المخصص لمنصة الويب فقط
// تم إنشاؤه لفصل الكود حسب المنصات وتحسين أداء التطبيق

import 'dart:html' as html;
import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/site_app/1/dated_orders_screen.dart';
import 'package:ElMassaConsult/site_app/1/get_new_orders/get_orders_link2page.dart';
import 'package:ElMassaConsult/site_app/1/surveying_order_deatils-screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// تم تعديل الكلاس ليكون خاص بمنصة الويب فقط
class NewOrdersScreen extends StatefulWidget {
  final String govName;
  final String userName;
  final String userCode;

  const NewOrdersScreen({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
  });

  @override
  State<NewOrdersScreen> createState() => _SiteTrackingTabBarScreenStateWeb();
}

class _SiteTrackingTabBarScreenStateWeb extends State<NewOrdersScreen> with SingleTickerProviderStateMixin {
  List<String> state = [
    "لم يتم الرفع",
    "إعادة المعاينة",
    "جارى الرسم",
  ];
 final ValueNotifier<bool> _isExporting = ValueNotifier(false);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: state.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: state.length,
      child: GestureDetector(
        onTap: () {
          if (_textFieldFocusNode.hasFocus) {
            _textFieldFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: state.map((status) => _buildTabContent(status)).toList(),
          ),
        ),
      ),
    );
  }



  AppBar _buildAppBar() {
    return AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.home, size: 35),
          onPressed: () {
            Get.offAll(() => SiteGovScreenWindows(userName: widget.userName));
          },
        ),
       
      ],
      title: Column(
        children: [
          Text("${widget.govName} - الموقع"),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: _buildSearchField(),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        tabs: state.map((status) {
          return Tab(
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
      ),
      centerTitle: true,
      toolbarHeight: 100,
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        focusNode: _textFieldFocusNode,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "البحث عن طلبات",
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildTabContent(String status) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('elmassaConsult')
                    .doc(widget.govName)
                    .collection('newOrders')
                    .where('team', isEqualTo: widget.userCode)
                    .where('orderStatus', isEqualTo: status)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("حدث خطأ اثناء جلب البيانات"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لم يتم اضافة طلبات بعد"));
                  }

                  List<NewOrderModel> filteredOrders = _filterOrders(snapshot);
                  if (filteredOrders.isEmpty) {
                    return const Center(
                        child: Text("لا توجد طلبات مطابقة للبحث"));
                  }

                  return _buildOrderList(filteredOrders);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<NewOrderModel> _filterOrders(AsyncSnapshot<QuerySnapshot> snapshot) {
    List<NewOrderModel> newOrderList = snapshot.data!.docs.map((doc) {
      return NewOrderModel.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();

   
    return newOrderList.where((order) {
      String query = _searchQuery.toLowerCase();
      return order.orderNumber.toLowerCase().contains(query) ||
          order.name.toLowerCase().contains(query) ||
          order.unitType.toLowerCase().contains(query)||
          order.distributionDate.toString().toLowerCase().contains(query)||
          order.sheikhdomOrVillage.toLowerCase().contains(query);
    }).toList();
  }

Widget _buildOrderList(List<NewOrderModel> orders) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              Get.to(() => DatedOrdersScreen(
                    govName: widget.govName,
                    userCode: widget.userCode,
                    userName: widget.userName,
                  ));
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text("طلبات محددة بموعد"),
          ),
     

          const SizedBox(width: 30),

          // ✅ عداد الطلبات
          CircleAvatar(child: Text("${orders.length}")),
               const SizedBox(width: 30),

   ElevatedButton(
  onPressed: () async {
    _isExporting.value = true;
    await _exportToExcel(widget.govName, widget.userCode);
    _isExporting.value = false;
  },
   style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 219, 20, 6),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  ),
  child: ValueListenableBuilder<bool>(
    valueListenable: _isExporting,
    builder: (_, isExporting, __) {
      if (isExporting) {
        return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Text("اخراج Excel طلبات ${state[_tabController.index]}");
    },
  ),
 
),

        ],
      ),
      const SizedBox(height: 10),
     ListView.builder(
  itemCount: orders.length,
  shrinkWrap: true,
  physics: const BouncingScrollPhysics(),
  itemBuilder: (context, i) {
    return _buildOrderCard(orders[i]);
  },
),

    ],
  );
}

Future<void> _exportToExcel(String govName, String userCode) async {
  _isExporting.value = true;
  try {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(govName)
        .collection('newOrders')
        .where('team', isEqualTo: userCode)
        .where('orderStatus', isEqualTo: state[_tabController.index])
        .get();

    if (ordersSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا توجد بيانات للتصدير")),
      );
      return;
    }

    var excelFile = Excel.createExcel();
    Sheet sheetObject = excelFile['Sheet1'];

    // ✅ الهيدر
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

    for (var i = 0; i < headers.length; i++) {
      sheetObject
          .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1'))
          .value = TextCellValue(headers[i]);
    }

    // ✅ البيانات
    int rowIndex = 2;
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      sheetObject.cell(CellIndex.indexByString('A$rowIndex')).value =
          TextCellValue(data['orderNumber']?.toString() ?? '');
      sheetObject.cell(CellIndex.indexByString('B$rowIndex')).value =
          data['distributionDate'] != null
              ? TextCellValue(
                  data['distributionDate'].toDate().toIso8601String())
              :  TextCellValue('');
      sheetObject.cell(CellIndex.indexByString('C$rowIndex')).value =
          data['surveyingDate'] != null
              ? TextCellValue(
                  data['surveyingDate'].toDate().toIso8601String())
              :  TextCellValue('');
      sheetObject.cell(CellIndex.indexByString('D$rowIndex')).value =
          TextCellValue(data['name'] ?? '');
      sheetObject.cell(CellIndex.indexByString('E$rowIndex')).value =
          TextCellValue(data['phoneNumber'] ?? '');
      sheetObject.cell(CellIndex.indexByString('F$rowIndex')).value =
          TextCellValue(data['unitType'] ?? '');
      sheetObject.cell(CellIndex.indexByString('G$rowIndex')).value =
          TextCellValue(data['areaM2'] ?? '');
      sheetObject.cell(CellIndex.indexByString('H$rowIndex')).value =
          TextCellValue(data['governorate'] ?? '');
      sheetObject.cell(CellIndex.indexByString('I$rowIndex')).value =
          TextCellValue(data['departmentOrCenter'] ?? '');
      sheetObject.cell(CellIndex.indexByString('J$rowIndex')).value =
          TextCellValue(data['sheikhdomOrVillage'] ?? '');
      sheetObject.cell(CellIndex.indexByString('K$rowIndex')).value =
          TextCellValue(data['unitNumber'] ?? '');
      sheetObject.cell(CellIndex.indexByString('L$rowIndex')).value =
          TextCellValue(data['streetName'] ?? '');
      sheetObject.cell(CellIndex.indexByString('M$rowIndex')).value =
          TextCellValue(data['distinctiveSigns'] ?? '');
      sheetObject.cell(CellIndex.indexByString('N$rowIndex')).value =
          TextCellValue(data['team'] ?? '');
      sheetObject.cell(CellIndex.indexByString('O$rowIndex')).value =
          TextCellValue(data['orderStatus'] ?? '');
      sheetObject.cell(CellIndex.indexByString('P$rowIndex')).value =
          TextCellValue(data['reasonForInability'] ?? '');
      sheetObject.cell(CellIndex.indexByString('Q$rowIndex')).value =
          TextCellValue(data['reviewStatus'] ?? '');
      sheetObject.cell(CellIndex.indexByString('R$rowIndex')).value =
          TextCellValue(data['companyName'] ?? '');
      sheetObject.cell(CellIndex.indexByString('S$rowIndex')).value =
          TextCellValue(data['engName'] ?? '');
      rowIndex++;
    }

    // ✅ حفظ الملف كـ Uint8List
    final fileBytes = excelFile.encode();

    // ✅ إنشاء رابط تحميل في المتصفح
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download",
          "orders_${govName}_${userCode}_${DateTime.now().millisecondsSinceEpoch}.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحميل ملف Excel بنجاح ✅')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e')),
    );
  } finally {
    _isExporting.value = false;
  }
}

  Widget _buildOrderCard(NewOrderModel order) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        onTap: () {
          Get.to(() => SurveyingOrderDeatilsScreen(
                newOrderModel: order,
                userName: widget.userName,
                userCode: widget.userCode,
                govName: widget.govName,
              ));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.distributionDate.toString()),
            if (_tabController.index == 0) // ✅ يظهر فقط في تبويب "لم يتم الرفع"
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.blue),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      DateTime finalDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      FirebaseFirestore.instance
                          .collection('elmassaConsult')
                          .doc(widget.govName)
                          .collection('newOrders')
                          .doc(order.orderNumber)
                          .update({
                        'dueDate': finalDateTime,
                        'orderStatus': 'طلبات محددة بموعد'
                      });

                      Get.snackbar("تم التحديث", "تم تحديد موعد للطلب");
                    }
                  }
                },
              ),
          ],
        ),
        title: Text(order.name),
        subtitle: Text(
              order.orderNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
                   
        ),
      ),
    );
  
}

}