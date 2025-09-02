import 'package:ElMassaConsult/controllers/notifications_controller/noti_stage_controller_link.dart';
import 'package:ElMassaConsult/site_app/1/accepted_orders_screen.dart';
import 'package:ElMassaConsult/site_app/1/canceling_order_screen.dart';
import 'package:ElMassaConsult/site_app/1/certificates_tobe_reviewed_screen.dart';
import 'package:ElMassaConsult/site_app/1/delivering_orders_screen.dart';
import 'package:ElMassaConsult/site_app/1/new_orders/new_orders_screen_link.dart';
import 'package:ElMassaConsult/site_app/1/rejected_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoriesSiteScreen extends StatefulWidget {
  final String govName;

  final String userName;

  final String userCode;

  const CategoriesSiteScreen({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
  });

  @override
  State<CategoriesSiteScreen> createState() => _CategoriesSiteScreenState();
}

class _CategoriesSiteScreenState extends State<CategoriesSiteScreen> {
  final List<String> dataSource = [
    "مرحلة الموقع",
    "تعذر الرفع",
    "مرفوض مكتب فنى",
    "تم التسليم وجارى المراجعة",
    "شهادات مطلوب مراجعتها",
    "طلبات مقبولة مكتب فنى"
  ];

  @override
  void initState() {
    super.initState();
    OfficeOrderWatcher().init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${widget.govName} - الموقع"),
      ),
      body: ListView(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: Get.width > 600 ? 3.5 : 3.5,
            ),
            itemCount: dataSource.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  switch (index) {
                    case 0:
                      Get.to(() => NewOrdersScreen(
                          govName: widget.govName,
                          userName: widget.userName,
                          userCode: widget.userCode));
                      break;
                    case 1:
                      Get.to(() => CancelingOrdersScreen(
                          govName: widget.govName,
                          userName: widget.userName,
                          userCode: widget.userCode));
                      break;
                    case 2:
                      Get.to(() => RejectedOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode,
                          ));
                      break;
                    case 3:
                      Get.to(
                        () => DeliveringOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                    case 4:
                      Get.to(
                        () => CertificatesTobeReviewedScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                      break;
                    case 5:
                      Get.to(
                        () => AcceptedOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                      break;
                    default:
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    dataSource[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 25,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
