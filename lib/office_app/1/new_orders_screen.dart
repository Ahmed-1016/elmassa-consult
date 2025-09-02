import 'package:ElMassaConsult/models/engdata-model.dart';
import 'dart:io';

import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen.dart';
import 'package:ElMassaConsult/office_app/1/surveying_order_deatils-screen.dart';
import 'package:ElMassaConsult/office_app/general/gov_screen_windows.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_textFieldFocusNode.hasFocus) {
          _textFieldFocusNode.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
          icon: Icon(Icons.home, size: 35),
          onPressed: () {if (Platform.isWindows) {Get.offAll(() => OfficeGovScreenWindows(userName: widget.userName));}else{Get.offAll(() => OfficeGovScreen(userName: widget.userName));}
            
          },
        ),
          ],
          title: Column(
            children: [
              Text("${widget.govName} - المكتب الفنى"),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
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
                    decoration: InputDecoration(
                      hintText: "البحث عن طلبات",
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
            ],
          ),
          centerTitle: true,
          toolbarHeight: 100,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('elmassaConsult')
              .doc(widget.govName)
              .collection('newOrders')
              .where('orderStatus', isEqualTo: widget.userCode)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("حدث خطأ اثناء جلب البيانات"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("لم يتم اضافة طلبات بعد"));
            }

            List<NewOrderModel> newOrderList = snapshot.data!.docs.map((doc) {
              return NewOrderModel.fromMap(doc.data() as Map<String, dynamic>);
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

            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                CircleAvatar(
                  child: Text("${filteredNewOrderList.length}"),
                ),
                ...filteredNewOrderList.map((newOrderModel) {
                  return Card(
                    elevation: 3,
                    child: ListTile(
                      onTap: () {
                        Get.to(
                          () => SurveyingOrderDeatilsScreen(
                            newOrderModel: newOrderModel,
                            userName: widget.userName,
                            userCode: widget.userCode,
                            govName: widget.govName,
                          ),
                        );
                      },
                      leading: Text(newOrderModel.engName),
                      trailing:newOrderModel.orderStatus == "Stage 1"?
                      
                       FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('elmassaConsult')
                            .doc(widget.govName)
                            .collection('newOrders')
                            .doc(newOrderModel.orderNumber)
                            .collection('editorDeatils')
                            .orderBy('createdOn')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text('Error'); // Or handle error differently
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text(''); // No documents or error, display empty
                          }

                          DateTime? dateToDisplay;

                          for (final engDataDoc in snapshot.data!.docs) {
                            final engData = EngData.fromMap(engDataDoc.data());
                            if (engData.orderStatus == "تم التسليم") {
                              dateToDisplay = engData.createdOn;
                              break;
                            }
                          }

                          if (dateToDisplay != null) {
                            return Text(_formatDate(dateToDisplay));
                          } else {
                            // No document with "تم التسليم" found or createdOn was unparsable
                            return Text("");
                          }
                        },
                      ):null,
                      title: Text(newOrderModel.name),
                      subtitle: Text(
                        newOrderModel.orderNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
   String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm:ss a').format(date);
  }
}
