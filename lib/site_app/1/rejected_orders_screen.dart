import 'dart:io';

import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen.dart';
import 'package:ElMassaConsult/site_app/1/surveying_order_deatils-screen.dart';
import 'package:ElMassaConsult/site_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RejectedOrdersScreen extends StatefulWidget {
  final String govName;

  final String userName;

  final String userCode;

  const RejectedOrdersScreen(
      {super.key,
      required this.govName,
      required this.userName,
      required this.userCode});

  @override
  State<RejectedOrdersScreen> createState() => CancelringOrdersScreenState();
}

class CancelringOrdersScreenState extends State<RejectedOrdersScreen> {
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
          icon: Icon(Icons.home, size: 35),
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
                decoration: InputDecoration(
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
                    .where('orderStatus', isEqualTo: 'مرفوض مكتب فنى')
                    .snapshots(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return Center(child: Text("حدث خطأ اثناء جلب البيانات"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لم يتم اضافة طلبات بعد"));
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
                      return Center(child: Text("لا توجد طلبات مطابقة للبحث"));
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
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, i) {
                            NewOrderModel newOrderModel =
                                filteredNewOrderList[i];

                            return Card(
                                elevation: 3,
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      onTap: () {
                                        Get.to(
                                          () => SurveyingOrderDeatilsScreen(
                                            newOrderModel: newOrderModel,
                                            userName: widget.userName,
                                            govName: widget.govName,
                                            userCode: widget.userCode,
                                          ),
                                        );
                                      },
                                      trailing: Text(newOrderModel.unitType),
                                      // leading: Text(productModel.engName),
                                      title: Text(newOrderModel.name),
                                      subtitle: Text(
                                        newOrderModel.orderNumber,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
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
