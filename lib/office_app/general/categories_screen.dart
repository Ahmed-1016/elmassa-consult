import 'package:ElMassaConsult/controllers/notifications_controller/noti_stage_controller_link.dart';
import 'package:ElMassaConsult/office_app/1/certificates_reviewed_screen.dart';
import 'package:ElMassaConsult/office_app/1/certificates_tobe_reviewed_screen.dart';
import 'package:ElMassaConsult/office_app/1/completed_orders_screen.dart';
import 'package:ElMassaConsult/office_app/1/get_comments/get_edit_comments.dart';
import 'package:ElMassaConsult/office_app/1/get_comments/get_regected_comments.dart';
import 'package:ElMassaConsult/office_app/1/rejected_orders_screen.dart';
import 'package:ElMassaConsult/office_app/1/new_orders_screen.dart';
import 'package:ElMassaConsult/office_app/1/review_orders_screen.dart';
import 'package:ElMassaConsult/services/notifications/notif.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ElMassaConsult/office_app/1/download_previous_file/download_previous_file.dart';


class CategoriesOfficeScreen extends StatefulWidget {
  final String govName;

  final String userName;

  final String userCode;

  const CategoriesOfficeScreen({
    super.key,
    required this.govName,
    required this.userName,
    required this.userCode,
  });

  @override
  State<CategoriesOfficeScreen> createState() => _CategoriesOfficeScreenState();
}

class _CategoriesOfficeScreenState extends State<CategoriesOfficeScreen> {
  late final List<String> dataSource;

  @override
  void initState() {
    super.initState();
    OfficeOrderWatcher().init(context);
    // تحديد عناصر القائمة بناءً على userCode
    dataSource = _getDataSourceBasedOnUserCode(widget.userCode);
  }

  List<String> _getDataSourceBasedOnUserCode(String userCode) {
    // تخصيص القائمة بناءً على قيمة userCode
    switch (userCode) {
      case "Stage 1":
        return [
          "مراحل اعداد الملفات",
          "مرفوض مكتب فنى",
          "إعادة المعاينة",
          "تحميل ملفات سابقة"
        ];
      case "Stage 2":
        return [
          "مراحل اعداد الملفات",
        ];
      case "Stage 3":
        return [
          "مراحل اعداد الملفات",
          "شهادات مطلوب مراجعتها",
          "شهادات تمت مراجعتها",
          "تم الارسال للإدارة",
        ];
      case "تعديلات":
        return [
          "تعليقات التعديلات"
        ];
      case "مرفوض":
        return [
          "تعليقات المرفوض"
        ];
      default:
        return [
          "لا توجد صلاحيات متاحة",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("${widget.govName} - المكتب الفنى"),
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
              childAspectRatio: Get.width > 600 ? 3 : 3.5,
            ),
            itemCount: dataSource.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  switch (dataSource[index]) {
                    case "مراحل اعداد الملفات":
                      Get.to(() => NewOrdersScreen(
                          govName: widget.govName,
                          userName: widget.userName,
                          userCode: widget.userCode));
                      break;
                    case "مرفوض مكتب فنى":
                      Get.to(() => RejectedOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode,
                          ));
                      break;
                    case "شهادات مطلوب مراجعتها":
                      Get.to(() => CertificatesTobeReviewedScreen(
                          govName: widget.govName,
                          userName: widget.userName,
                          userCode: widget.userCode));
                      break;
                    case "شهادات تمت مراجعتها":
                      Get.to(
                        () => CertificatesReviewedScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                      break;
                    case "تم الارسال للإدارة":
                      Get.to(
                        () => CompletedOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                    case "إعادة المعاينة":
                      Get.to(
                        () => ReviewOrdersScreen(
                            govName: widget.govName,
                            userName: widget.userName,
                            userCode: widget.userCode),
                      );
                      break;
                    case "تعليقات التعديلات":
                      Get.to(() => const GetEditComments());
                      break;
                    case "تعليقات المرفوض":
                      Get.to(() => const GetRejectedComments());
                      break;
                    case "تحميل ملفات سابقة":
                      Get.to(() => const DownloadPreviousFiles());
                      break;
                    default:
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.info,
                        title: "تنبيه",
                        desc: "لا توجد صلاحيات متاحة",
                      ).show();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
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
