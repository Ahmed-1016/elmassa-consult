import 'dart:io';
import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/site_app/1/get_new_orders/get_orders_form_server_mobile.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:ElMassaConsult/site_app/1/surveying_order_deatils-screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DatedOrdersScreen extends StatefulWidget {
  final String govName;
  final String userName;
  final String userCode;

  const DatedOrdersScreen({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
  });

  @override
  State<DatedOrdersScreen> createState() => _SiteTrackingTabBarScreenState();
}

class _SiteTrackingTabBarScreenState extends State<DatedOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<String> state = ["طلبات محددة بموعد"];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  String _searchQuery = '';
  late TabController _tabController;
  final ValueNotifier<bool> isUploadingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: state.length, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // تحديث الواجهة عند تغيير التاب
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
    final bool isFirstTab = _tabController.index == 0;

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
            if (Platform.isWindows) {
              Get.offAll(() => SiteGovScreenWindows(userName: widget.userName));
            } else {
              Get.offAll(() => SiteGovScreen(userName: widget.userName));
            }
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
                    // هنا بنلغي الـ orderBy من Firestore ونرتب بعدين في الكود
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("حدث خطأ اثناء جلب البيانات"),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لم يتم اضافة طلبات بعد"));
                  }

                  List<NewOrderModel> filteredOrders = _filterOrders(snapshot);

                  // ترتيب الطلبات يدويًا بالـ dueDate
                  filteredOrders.sort((a, b) {
                    if (a.dueDate == null && b.dueDate == null) return 0;
                    if (a.dueDate == null) return 1; // null يروح تحت
                    if (b.dueDate == null) return -1;
                    return a.dueDate!.compareTo(b.dueDate!);
                  });

                  if (filteredOrders.isEmpty) {
                    return const Center(
                      child: Text("لا توجد طلبات مطابقة للبحث"),
                    );
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
          order.unitType.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildOrderList(List<NewOrderModel> orders) {
    return Column(
      children: [
        CircleAvatar(child: Text("${orders.length}")),
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: Get.width > 600 ? 16 : 3.25,
          ),
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

  Widget _buildOrderCard(NewOrderModel order) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          onTap: () async {
            if (order.dueDate != null &&
                order.dueDate!.isBefore(DateTime.now())) {
              // الطلب متأخر → نعرض Dialog
              _showExpiredOrderDialog(order);
            } else {
              // الطلب عادي → افتح صفحة التفاصيل
              Get.to(
                () => SurveyingOrderDeatilsScreen(
                  newOrderModel: order,
                  userName: widget.userName,
                  userCode: widget.userCode,
                  govName: widget.govName,
                ),
              );
            }
          },
          leading: IconButton(
      tooltip: "تغيير الحالة إلى لم يتم الرفع",
      icon: const Icon(Icons.close,size: 16),
      color: Colors.red,
      style: IconButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _confirmResetOrder(order),
    ),
          trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      order.dueDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(order.dueDate!)
          : "بدون موعد",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: order.dueDate != null && order.dueDate!.isBefore(DateTime.now())
            ? Colors.red
            : Colors.black,
      ),
    ),
    if (order.dueDate != null && order.dueDate!.isBefore(DateTime.now()))
      const Icon(Icons.warning, color: Colors.red, size: 16),
    
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

 void _showExpiredOrderDialog(NewOrderModel order) {
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text("تنبيه"),
        content: const Text("ميعاد الطلب انتهى، هل تريد إعادة جدولة؟"),
        actions: [
          TextButton(
            onPressed: () async {
              navigator.pop(); // Close the dialog

              try {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );

                if (pickedDate == null) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null && mounted) {
                  final finalDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  await FirebaseFirestore.instance
                      .collection('elmassaConsult')
                      .doc(widget.govName)
                      .collection('newOrders')
                      .doc(order.orderNumber)
                      .update({"dueDate": finalDateTime});
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('حدث خطأ أثناء تحديث الموعد')),
                  );
                }
              }
            },
            child: const Text("إعادة جدولة"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('elmassaConsult')
                    .doc(widget.govName)
                    .collection('newOrders')
                    .doc(order.orderNumber)
                    .update({"orderStatus": "لم يتم الرفع","dueDate": null});
                if (mounted) navigator.pop();
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('حدث خطأ أثناء تحديث حالة الطلب')),
                  );
                }
              }
            },
            child: const Text("لا"),
          ),
        ],
      );
    },
  );
}
void _confirmResetOrder(NewOrderModel order) {
  final navigator = Navigator.of(context);
  final snack = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("تأكيد"),
      content: Text("هل تريد تغيير حالة الطلب ${order.orderNumber} إلى \"لم يتم الرفع\" ومسح الموعد؟"),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text("إلغاء"),
        ),
        TextButton(
          onPressed: () async {
            navigator.pop(); // اقفل الدIALOG
            try {
              await FirebaseFirestore.instance
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(order.orderNumber)
                  .update({
                    "orderStatus": "لم يتم الرفع",
                    // إمّا نمسح الحقل
                    // "dueDate": FieldValue.delete(),

                    // أو نخليه null (مفضل لو الموديل بيقبل null)
                    "dueDate": null,
                  });

              if (!mounted) return;
              snack.showSnackBar(
                const SnackBar(content: Text("تم تغيير الحالة ومسح الموعد")),
              );
            } catch (e) {
              if (!mounted) return;
              snack.showSnackBar(
                const SnackBar(content: Text("حدث خطأ أثناء التحديث")),
              );
            }
          },
          child: const Text("تأكيد"),
        ),
      ],
    ),
  );
}


}
