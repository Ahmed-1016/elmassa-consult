import 'dart:io';

import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/site_app/1/site_download/site_download_link.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AcceptedOrdersScreen extends StatefulWidget {
  final String govName;

  final String userName;

  final String userCode;

  const AcceptedOrdersScreen({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
  });

  @override
  State<AcceptedOrdersScreen> createState() => AcceptedOrdersScreenState();
}

class AcceptedOrdersScreenState extends State<AcceptedOrdersScreen> {
  final TextEditingController _searchController =
      TextEditingController(); // متحكم لحقل البحث

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${widget.govName} - الموقع"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:  IconButton(
          icon: const Icon(Icons.home, size: 35),
          onPressed: () {if (Platform.isWindows) {Get.offAll(() => SiteGovScreenWindows(userName: widget.userName));}else{Get.offAll(() => SiteGovScreen(userName: widget.userName));}
            
          },
        ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery =
                        value.toLowerCase(); // تحديث الاستعلام عند تغيير النص
                  });
                },
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "إبحث عن طلبات",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('elmassaConsult')
                    .doc(widget.govName)
                    .collection('newOrders')
                    .where('team', isEqualTo: widget.userCode)
                    .where('orderStatus', isEqualTo: 'تم الارسال الى الإدارة')
                    .snapshots(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("حدث خطأ اثناء جلب البيانات"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لم يتم اضافة طلبات بعد"));
                  }
                  if (snapshot.data != null) {
                    List<NewOrderModel> newOrderList =
                        snapshot.data!.docs.map((doc) {
                      return NewOrderModel.fromMap(
                          doc.data() as Map<String, dynamic>);
                    }).toList();

                    List<NewOrderModel> filteredNewOrderList =
                        newOrderList.where((order) {
                      String query = _searchQuery.toLowerCase();
                      return order.orderNumber.toLowerCase().contains(query) ||
                          order.name.toLowerCase().contains(query) ||
                          order.unitType.toLowerCase().contains(query);
                    }).toList();

                    if (filteredNewOrderList.isEmpty) {
                      return const Center(child: Text("لا توجد طلبات مطابقة للبحث"));
                    }

                    return Column(
                      children: [
                        CircleAvatar(
                            child: Text("${filteredNewOrderList.length}")),
                        GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: Get.width > 600 ? 16 : 3.25,
                          ),
                          itemCount: filteredNewOrderList.length,
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, i) {
                            NewOrderModel newOrderModel =
                                filteredNewOrderList[i];

                            return Card(
                                elevation: 3,
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: IconButton(
                                          onPressed: () {
                                            downloadFileAction(
                                                context,
                                                newOrderModel.orderNumber,
                                                newOrderModel.name);
                                          },
                                          icon: const Icon(
                                            Icons.download,
                                            size: 30,
                                            color: Colors.green,
                                          )),
                                      trailing: Text(newOrderModel.unitType),
                                      // leading: Text(productModel.engName),
                                      title: Text(newOrderModel.name),
                                      subtitle: Text(
                                        newOrderModel.orderNumber,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    )));
                          },
                        ),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
