// ignore_for_file: file_names, avoid_unnecessary_containers, must_be_immutable

import 'dart:io';

import 'package:ElMassaConsult/models/comments_model.dart';
import 'package:ElMassaConsult/site_app/1/Image_viewer/image_viewer_link.dart';

import 'package:ElMassaConsult/site_app/1/rejected_chat_screen.dart';
import 'package:ElMassaConsult/models/engdata-model.dart';
import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/site_app/1/site_upload.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';
import 'package:get/get.dart';

class SurveyingOrderDeatilsScreen extends StatefulWidget {
  final NewOrderModel newOrderModel;
  final String userName;
  final String govName;
  final String userCode;

  const SurveyingOrderDeatilsScreen({
    super.key,
    required this.newOrderModel,
    required this.userName,
    required this.govName,
    required this.userCode,
  });

  @override
  State<SurveyingOrderDeatilsScreen> createState() =>
      SurveyingsOrderDeatilsScreenState();
}

class SurveyingsOrderDeatilsScreenState
    extends State<SurveyingOrderDeatilsScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final DriveService _driveService = DriveService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "تفاصيل الطلب",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildRowOrderNumberAndCopy(),
              _buildOrderDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowOrderNumberAndCopy() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildOrderNumber(), _buildCopyIconButton()],
    );
  }

  Widget _buildCopyIconButton() {
    return IconButton(
        onPressed: () {
          Clipboard.setData(
              ClipboardData(text: widget.newOrderModel.orderNumber));
        },
        icon: const Icon(Icons.copy, size: 30));
  }

  Widget _buildOrderNumber() {
    return Container(
      child: Text(
        widget.newOrderModel.orderNumber,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return SizedBox(
      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 1.1,
      child: Card(
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            _buildOrderDetailsTable(),
            _arrangeButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {1: FlexColumnWidth(Get.width / 180)},
        border: TableBorder.all(),
        children: [
          _buildTableRow("اسم مقدم الطلب", widget.newOrderModel.name),
          _buildPhoneNumberRow(),
          _buildTableRow("نوع الوحدة", widget.newOrderModel.unitType),
          _buildTableRow("المساحة م2", "${widget.newOrderModel.areaM2} م2"),
          _buildTableRow("المحافظة", widget.newOrderModel.governorate),
          _buildTableRow(
              "القسم / المركز", widget.newOrderModel.departmentOrCenter),
          _buildTableRow(
              "الشياخة / القرية", widget.newOrderModel.sheikhdomOrVillage),
          _buildTableRow("رقم الوحدة", widget.newOrderModel.unitNumber),
          _buildTableRow("اسم الشارع", widget.newOrderModel.streetName),
          _buildTableRow("علامات مميزة", widget.newOrderModel.distinctiveSigns),
          _buildTableRow("تاريخ رفع الطلب:",
              _formatDate(widget.newOrderModel.surveyingDate)),
          _buildTableRow("تاريخ التوزيع:",
              _formatDate(widget.newOrderModel.distributionDate)),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  TableRow _buildPhoneNumberRow() {
    return TableRow(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("رقم الهاتف"),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.newOrderModel.phoneNumber),
              if (!kIsWeb && Platform.isAndroid && !Platform.isWindows)
                IconButton(
                  onPressed: () async {
                    String phoneNumber = widget.newOrderModel.phoneNumber;
                    if (!phoneNumber.startsWith('0')) {
                      phoneNumber = '0$phoneNumber';
                    }
                    await FlutterDirectCallerPlugin.callNumber(phoneNumber);
                  },
                  icon: const Icon(Icons.call, color: Colors.blue),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _arrangeButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getActionButtonsRow1(),
          ),
        ],
      ),
    );
  }

  List<Widget> _getActionButtonsRow1() {
    switch (widget.newOrderModel.orderStatus) {
      case "لم يتم الرفع"|| "طلبات محددة بموعد":
        return [
          _buildActionButton(
            "تعذر الرفع",
            Colors.purple,
            () => _handleTransition("تعذر الرفع", "تعذر الرفع", true),
            const Icon(Icons.report_problem, color: Colors.white),
          ),
          _buildActionButton(
            "تم الرفع",
            Colors.green,
            () => _handleTransition("تم الرفع", "جارى الرسم", false),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      // case "تم الرفع":
      //   return [
      //     _buildActionButton(
      //       "تم الرسم",
      //       Colors.blue,
      //       () => _handleTransition("تم الرسم", "تم الرسم", false),
      //       const Icon(Icons.arrow_forward, color: Colors.white),
      //     )
      //   ];
      case "إعادة المعاينة":
        return [
          _buildActionButton(
            "محادثة",
            Colors.orange,
            () => _chatScreen(),
            const Icon(Icons.chat, color: Colors.white),
          ),
          _buildActionButton(
            "جارى الرسم",
            Colors.blue,
            () => _handleTransition("إعادة المعاينة", "جارى الرسم", false),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "جارى الرسم":
        return [
          _buildActionButton(
            "تسليم الملف",
            Colors.green,
            () => _handleTransition("تم التسليم", "Stage 1", false),
            const Icon(Icons.arrow_forward, color: Colors.white),
          )
        ];
      case "تعذر الرفع":
        return [
          _buildActionButton(
            "عرض سبب التعذر",
            Colors.red,
            () => _showEngComments(isRejected: false),
            const Icon(Icons.comment, color: Colors.white),
          )
        ];
      case "مرفوض مكتب فنى":
        return [
          _buildActionButton(
            "محادثة",
            Colors.purple,
            () => _chatScreen(),
            const Icon(Icons.chat, color: Colors.white),
          ),
          _buildActionButton(
            "تسليم الملف",
            Colors.green,
            () => _handleTransition("تم التسليم", "Stage 1", false),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "شهادات مطلوب مراجعتها":
        return [
          _buildActionButton(
            "تم مراجعة الشهادة",
            Colors.green,
            () => _handleTransition("تم التسليم", "شهادات تمت مراجعتها", false),
            const Icon(Icons.reviews, color: Colors.white),
          ),
          _buildActionButton(
            "عرض الصور",
            Colors.blue,
            () => Get.to(() => ImageViewerPage(
                requestNumber: widget.newOrderModel.orderNumber)),
            const Icon(Icons.image, color: Colors.white),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildActionButton(
      String label, Color color, VoidCallback onPressed, Icon icon) {
    return Material(
      child: Container(
        width: Get.width / 2.3,
        height: Get.height / 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextButton.icon(
            onPressed: onPressed,
            label: Text(
              label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            icon: icon),
      ),
    );
  }

  Future<void> _handleTransition(
      String currentStatus, String nextStatus, bool isRejected) async {
    EngData engdata = EngData(
        orderNumber: widget.newOrderModel.orderNumber,
        username: widget.userName,
        usercode: widget.userCode,
        createdOn: DateTime.now(),
        orderStatus: currentStatus);

    try {
      isRejected
          ? await _addCommentsDialog(engdata, nextStatus)
          : await _confirmDialog(engdata, nextStatus);
    } catch (e) {
      _showErrorSnackbar(e);
    }
  }

  Future<void> _changeOrderStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(widget.govName)
        .collection('newOrders')
        .doc(widget.newOrderModel.orderNumber)
        .update({"orderStatus": status});
  }

  Future<void> _addToEditorDeatils(EngData engData) async {
    await FirebaseFirestore.instance
        .collection('elmassaConsult')
        .doc(widget.govName)
        .collection('newOrders')
        .doc(widget.newOrderModel.orderNumber)
        .collection('editorDeatils')
        .add(engData.toMap());
  }

  Future<void> _updateOrAddOfficeTeamWorkRate(EngData engdata) async {
    try {
      final officeteamWorkRef = FirebaseFirestore.instance
          .collection('PrSiteTeamWork')
          .doc(widget.userName)
          .collection('PerRate');
      await FirebaseFirestore.instance
          .collection('PrSiteTeamWork')
          .doc(widget.userName)
          .set({'userName': widget.userName});
      final existingofficeTeamWork = await officeteamWorkRef
          .where('orderNumber', isEqualTo: widget.newOrderModel.orderNumber)
          .get();

      if (existingofficeTeamWork.docs.isNotEmpty) {
        await officeteamWorkRef
            .doc(existingofficeTeamWork.docs.first.id)
            .update(engdata.toMap());
      } else {
        await officeteamWorkRef.add(engdata.toMap());
      }
    } catch (e) {
      _showErrorSnackbar(e);
    }
  }

  void _showErrorSnackbar(Object e) {
    Get.snackbar(
      "خطأ",
      "حدث خطأ: $e",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> _chatScreen() async {
    // Navigate to the new chat screen
    Get.to(
      () => RejectedChatScreen(
        orderNumber: widget.newOrderModel.orderNumber,
        name: widget.newOrderModel.name,
        userName: widget.userName,
        userCode: widget.userCode,
        govName: widget.govName,
      ),
    );
  }

  Future<void> _addCommentsDialog(EngData engdate, String nextStatus) async {
    await AwesomeDialog(
        width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
        context: context,
        body: Column(
          children: [
            const Text(
              "اكتب سبب التعذر",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              maxLines: 4,
              minLines: 3,
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ],
        ),
        btnCancelOnPress: () {},
        btnOkOnPress: () async {
          final comments = _nameController.text.trim();

          if (comments.isNotEmpty || comments != "") {
            CommentsModel commentsModel = CommentsModel(
              orderNumber: widget.newOrderModel.orderNumber,
              username: widget.userName,
              usercode: widget.userCode,
              createdOn: DateTime.now(),
              comments: comments,
            );

            await FirebaseFirestore.instance
                .collection('elmassaConsult')
                .doc(widget.govName)
                .collection('newOrders')
                .doc(widget.newOrderModel.orderNumber)
                .collection('canceling')
                .doc(widget.newOrderModel.orderNumber)
                .set(commentsModel.toMap());
            EngData engdata = engdate;
            String nextStatusForDialog = nextStatus;
            await _addToEditorDeatils(engdata);
            await _updateOrAddOfficeTeamWorkRate(engdata);
            await _changeOrderStatus(nextStatusForDialog);

            Get.snackbar(
              "تم تحديث البيانات",
              "تم نقل الطلب الى $nextStatus بنجاح",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            await Future.delayed(
              const Duration(seconds: 2),
            );
            Get.back(closeOverlays: true);
          } else {
            Get.snackbar(
              "خطأ",
              "لايمكن ترك سبب التعذر فارغ",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }).show();
  }

  
  Future<void> _confirmDialog(EngData engdata, String nextStatus) async {
    final isStage1 = nextStatus == "Stage 1";

    await AwesomeDialog(
        width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
        context: context,
        title: "تأكيد إجراء",
        body: isStage1
            ? Column(
                children: [
                  const Text(
                    "اكتب تعليق",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    maxLines: 4,
                    minLines: 3,
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        // dismissOnTouchOutside: isStage1,
        // dismissOnBackKeyPress: isStage1,
        btnCancelOnPress: () async {
          if (isStage1) {
            bool uploaded = await _uploadFile(engdata);
            if (!uploaded) return;
            try {
              CommentsModel commentsModel = CommentsModel(
                orderNumber: widget.newOrderModel.orderNumber,
                username: widget.userName,
                usercode: widget.userCode,
                createdOn: DateTime.now(),
                comments: "لايوجد تعليق",
              );

              await FirebaseFirestore.instance
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(widget.newOrderModel.orderNumber)
                  .collection('comments')
                  .add(commentsModel.toMap());

              await FirebaseFirestore.instance
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(widget.newOrderModel.orderNumber)
                  .update(
                      {"engName": widget.userName, "orderStatus": "Stage 1"});

              await _addToEditorDeatils(engdata);
              await _updateOrAddOfficeTeamWorkRate(engdata);
              Get.snackbar(
                "تم تحديث البيانات",
                "تم نقل الطلب الى $nextStatus بنجاح",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              await Future.delayed(
                const Duration(seconds: 2),
              );
              Get.back(closeOverlays: true);
            } catch (e) {
              Get.snackbar(
                "خطأ",
                "حدث خطأ أثناء تحديث البيانات: $e",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }
          }
        },
        btnOkText: "تأكيد",
        btnCancelText: isStage1 ? "لايوجد تعليق" : "إلغاء",
        btnOkOnPress: () async {
          try {
            if (isStage1) {
              final comments = _nameController.text.trim();
              if (comments.isEmpty) {
                Get.snackbar(
                  "خطأ",
                  "لايمكن التأكيد بدون تعليق",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              bool uploaded = await _uploadFile(engdata);
              if (!uploaded) return;

              CommentsModel commentsModel = CommentsModel(
                orderNumber: widget.newOrderModel.orderNumber,
                username: widget.userName,
                usercode: widget.userCode,
                createdOn: DateTime.now(),
                comments: comments,
              );

              await FirebaseFirestore.instance
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(widget.newOrderModel.orderNumber)
                  .collection('comments')
                  .add(commentsModel.toMap());

              await FirebaseFirestore.instance
                  .collection('elmassaConsult')
                  .doc(widget.govName)
                  .collection('newOrders')
                  .doc(widget.newOrderModel.orderNumber)
                  .update(
                      {"engName": widget.userName, "orderStatus": "Stage 1"});

              await _addToEditorDeatils(engdata);
              await _updateOrAddOfficeTeamWorkRate(engdata);
              Get.snackbar(
                "تم تحديث البيانات",
                "تم نقل الطلب الى $nextStatus بنجاح",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );

            } else {
              await _addToEditorDeatils(engdata);
              await _updateOrAddOfficeTeamWorkRate(engdata);
              await _changeOrderStatus(nextStatus);

              Get.snackbar(
                "تم تحديث البيانات",
                "تم نقل الطلب الى $nextStatus بنجاح",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            }

            await Future.delayed(const Duration(seconds: 2));
            Get.back(closeOverlays: true);
          } catch (e) {
            Get.snackbar(
              "خطأ",
              "حدث خطأ أثناء تحديث البيانات: $e",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }
        }).show();
  }

  Future<bool> _uploadFile(EngData engdata) async {
    try {
      return await _driveService.uploadFileFromDevice(
        context,
        fileName: widget.newOrderModel.orderNumber,
        orderNumber: widget.newOrderModel.orderNumber,
        userName: widget.userName,
        govName: widget.govName,
        userCode: widget.userCode,
        engData: engdata,
      );
    } catch (e) {
      _showErrorSnackbar(e);
      return false;
    }
  }

  Future<void> _showEngComments({bool? isRejected}) async {
    String collection;
    if (isRejected == true) {
      collection = "rejected";
    } else if (isRejected == false) {
      collection = "canceling";
    } else {
      collection = "review_on_site";
    }
    AwesomeDialog(
      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
      dialogType: DialogType.info,
      context: context,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('elmassaConsult')
            .doc(widget.govName)
            .collection('newOrders')
            .doc(widget.newOrderModel.orderNumber)
            .collection(collection)
            .orderBy('createdOn', descending: true)
            // .doc(widget.newOrderModel.orderNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // أثناء التحميل
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            // إذا حدث خطأ
            return const Center(
              child: Text(
                "حدث خطأ أثناء جلب البيانات",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // إذا لم تكن هناك بيانات
            return const Center(
              child: Text(
                "لا توجد بيانات متاحة",
                style: TextStyle(color: Colors.grey),
              ),
            );
          } else {
            final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];

                final String userName = doc['username'] ?? "غير معروف";
                final String comments = doc['comments'] ?? "لا يوجد تعليق";
                final String usercode = doc['usercode'] ?? "لا يوجد تعليق";
                final DateTime date = (doc['createdOn'] as Timestamp).toDate();

                // إذا كانت البيانات موجودة

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                " الاسم : $userName",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " الكود : $usercode",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            " التاريخ :${_formatDate(date)}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "التعليق: $comments",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Divider()
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    ).show();
  }
}
