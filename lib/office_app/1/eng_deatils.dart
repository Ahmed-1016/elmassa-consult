import 'dart:io';

import 'package:ElMassaConsult/models/engdata-model.dart';
import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EngDeatils extends StatefulWidget {
  final String govName;

  final String userName;

  final String userCode;

  final NewOrderModel newOrderModel;

  const EngDeatils({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
    required this.newOrderModel,
  });

  @override
  State<EngDeatils> createState() => EngDeatilsState();
}

class EngDeatilsState extends State<EngDeatils> {
  final TextEditingController _searchController =
      TextEditingController(); // متحكم لحقل البحث
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${widget.govName} - المكتب الفنى"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:IconButton(
          icon: Icon(Icons.home, size: 35),
          onPressed: () {if (Platform.isWindows) {Get.offAll(() => OfficeGovScreenWindows(userName: widget.userName));}else{Get.offAll(() => OfficeGovScreen(userName: widget.userName));}
            
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
              child: FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('elmassaConsult')
                    .doc(widget.govName)
                    .collection('newOrders')
                    .doc(widget.newOrderModel.orderNumber)
                    .collection('editorDeatils')
                    .orderBy('createdOn')
                    .get(),
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
                    return Center(child: Text("لايوجد بيانات بعد"));
                  }
                  if (snapshot.data != null) {
                    List<EngData> engdata = snapshot.data!.docs.map((doc) {
                      return EngData.fromMap(
                          doc.data() as Map<String, dynamic>);
                    }).toList();

                    List<EngData> filteredNewOrderList = engdata.where((order) {
                      String query = _searchQuery.toLowerCase();
                      return order.orderNumber.toLowerCase().contains(query) ||
                          order.username.toLowerCase().contains(query) ||
                          order.usercode.toLowerCase().contains(query);
                    }).toList();

                    if (filteredNewOrderList.isEmpty) {
                      return Center(child: Text("لا توجد بيانات مطابقة للبحث"));
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
                            EngData engData = filteredNewOrderList[i];

                            return Card(
                                elevation: 3,
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      onTap: () {},
                                      trailing: Text(
                                        ('${(engData.createdOn).day}/${(engData.createdOn).month}/${(engData.createdOn).year} '),
                                      ),
                                      leading: Text(engData.orderStatus),
                                      // leading: Text(productModel.engName),
                                      title: Text(engData.username),
                                      subtitle: Text(
                                        engData.usercode,
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
