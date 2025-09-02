// ignore_for_file: file_names, avoid_unnecessary_containers, must_be_immutable

import 'dart:io' show Platform;

import 'package:ElMassaConsult/models/comments_model.dart';
import 'package:ElMassaConsult/models/engdata-model.dart';
import 'package:ElMassaConsult/models/new_order-model.dart';
import 'package:ElMassaConsult/office_app/1/rejected_chat_screen.dart';
import 'package:ElMassaConsult/office_app/1/office_download/office_download.dart';
import 'package:ElMassaConsult/office_app/1/office_upload_link.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';
import 'package:ElMassaConsult/office_app/1/image_viewer_page.dart';
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
  // المتغيرات
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // واجهة المستخدم
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
              _buildRowOrderNumber(),
              _buildRowDownAndUpAndCopy(),
              _buildOrderDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // عناصر واجهة المستخدم
  Widget _buildRowOrderNumber() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildOrderNumber()],
    );
  }

  // عناصر واجهة المستخدم
  Widget _buildRowDownAndUpAndCopy() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCopyIconButton(),
        if (widget.newOrderModel.orderStatus == "Stage 1")
          _iconDownloadButton(
            '1-5QqDEa_xPetpe3IKq1AbmhFsSezcxKj',
            "تحميل ملفات الموقع",
          ),
        if (widget.newOrderModel.orderStatus == "Stage 2")
          _iconDownloadButton(
            '1h8oObHLZcpDN_JsZReq0cBhdSrIl9Smc',
            "تحميل ملفات المرحلة الاولى",
          ),
      ],
    );
  }

  Widget _iconDownloadButton(String folderId, String folderName) {
    return TextButton.icon(
      label: Text(folderName),
      onPressed: () {
        downloadFileAction(
          context,
          widget.newOrderModel.orderNumber,
          widget.newOrderModel.name,
          folderId,
        );
      },
      icon: const Icon(Icons.download, size: 30, color: Colors.green),
    );
  }

  Widget _buildOrderNumber() {
    return Container(
      child: Text(
        widget.newOrderModel.orderNumber,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCopyIconButton() {
    return TextButton.icon(
      label: const Text("نسخ رقم الطلب"),
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: widget.newOrderModel.orderNumber),
        );
      },
      icon: const Icon(Icons.copy, size: 30),
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
        child: Column(children: [_buildOrderDetailsTable(), _arrangeButtons()]),
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
            "القسم / المركز",
            widget.newOrderModel.departmentOrCenter,
          ),
          _buildTableRow(
            "الشياخة / القرية",
            widget.newOrderModel.sheikhdomOrVillage,
          ),
          _buildTableRow("رقم الوحدة", widget.newOrderModel.unitNumber),
          _buildTableRow("اسم الشارع", widget.newOrderModel.streetName),
          _buildTableRow("علامات مميزة", widget.newOrderModel.distinctiveSigns),
          _buildTableRow(
            "تاريخ رفع الطلب",
            _formatDate(widget.newOrderModel.surveyingDate),
          ),
          _buildTableRow(
            "تاريخ التوزيع",
            _formatDate(widget.newOrderModel.distributionDate),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(label)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(value)),
      ],
    );
  }

  TableRow _buildPhoneNumberRow() {
    return TableRow(
      children: [
        const Padding(padding: EdgeInsets.all(8.0), child: Text("رقم الهاتف")),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.newOrderModel.phoneNumber),
              if (!kIsWeb && !Platform.isWindows && Platform.isAndroid)
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

  // الأزرار
  Widget _arrangeButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getActionButtonsRow1(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getActionButtonsRow2(),
          ),
        ],
      ),
    );
  }

  List<Widget> _getActionButtonsRow1() {
    switch (widget.newOrderModel.orderStatus) {
      case "Stage 1":
        return [
          _buildStageButton(
            "مرفوض مكتب",
            Colors.purple,
            () => _handleTransition(
              "Stage 1",
              "مرفوض مكتب فنى",
              isRejected: true,
            ),
            const Icon(Icons.report_problem, color: Colors.white),
          ),
          _buildStageButton(
            "To Stage 2",
            Colors.green,
            () async {
              bool uploaded = await _uploadFile(
                '1h8oObHLZcpDN_JsZReq0cBhdSrIl9Smc',
                'rar',
              );
              if (uploaded) {
                _handleTransition("Stage 1", "Stage 2", isRejected: false);
              }
            },
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "Stage 2":
        return [
          _buildStageButton(
            "To Stage 1",
            Colors.red,
            () => _handleTransition("Stage 2", "Stage 1", isRejected: false),
            const Icon(Icons.arrow_back, color: Colors.white),
          ),
          _buildStageButton(
            "To Stage 3",
            Colors.green,
            () => _handleTransition("Stage 2", "Stage 3", isRejected: false),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "Stage 3":
        return [
          _buildStageButton(
            "To Stage 2",
            Colors.red,
            () => _handleTransition("Stage 3", "Stage 2", isRejected: false),
            const Icon(Icons.arrow_back, color: Colors.white),
          ),
          _buildStageButton(
            "مراجعة الشهادة",
            Colors.green,
            () async {
              _handleTransition(
                "Stage 3",
                "شهادات مطلوب مراجعتها",
                isRejected: false,
              );
              await _uploadFile('1zy4sG4Fg8FlQQbroG1xkvyo0NjXZ1ahG', 'jpg');
            },
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "شهادات تمت مراجعتها":
        return [
          _buildStageButton(
            " الارسال للإدارة",
            Colors.green,
            () => _handleTransition(
              "شهادات مطلوب مراجعتها",
              "تم الارسال الى الإدارة",
              isRejected: false,
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "مرفوض مكتب فنى":
        return [
          _buildStageButton(
            "محادثة",
            Colors.purple,
            () => _chatScreen(),
            const Icon(Icons.chat, color: Colors.white),
          ),
        ];
      case "إعادة المعاينة":
        return [
          _buildStageButton(
            "محادثة",
            Colors.amber,
            () => _chatScreen(),
            const Icon(Icons.chat, color: Colors.white),
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _getActionButtonsRow2() {
    switch (widget.newOrderModel.orderStatus) {
      case "Stage 1":
        return [
          _buildStageButton(
            "عرض التعليقات",
            Colors.amber,
            () => _showEngComments(false),
            const Icon(Icons.comment, color: Colors.white),
          ),
          _buildStageButton(
            "إعادة المعاينة",
            Colors.red,
            () => _handleTransition("Stage 1", "إعادة المعاينة"),
            const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ];
      case "Stage 2":
        return [
          _buildStageButton(
            "عرض التعليق",
            Colors.amber,
            () => _showEngComments(false),
            const Icon(Icons.comment, color: Colors.white),
          ),
        ];
      case "Stage 3":
        return [
          _buildStageButton(
            "عرض التعليق",
            Colors.amber,
            () => _showEngComments(false),
            const Icon(Icons.comment, color: Colors.white),
          ),
          _buildStageButton(
            " الارسال للإدارة",
            Colors.blue,
            () async {
              _handleTransition(
                "Stage 3",
                 "تم الارسال الى الإدارة",
                isRejected: false,
              );
              await _uploadFile('1zy4sG4Fg8FlQQbroG1xkvyo0NjXZ1ahG', 'jpg');
            },

            const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ];
      case "شهادات مطلوب مراجعتها":
        return [
          _buildStageButton(
            "عرض التعليق",
            Colors.amber,
            () => _showEngComments(false),
            const Icon(Icons.comment, color: Colors.white),
          ),
          _buildStageButton(
            "عرض الصور",
            Colors.blue,
            () => Get.to(
              () => ImageViewerPage(
                requestNumber: widget.newOrderModel.orderNumber,
              ),
            ),
            const Icon(Icons.image, color: Colors.white),
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildStageButton(
    String label,
    Color color,
    VoidCallback onPressed,
    Icon icon,
  ) {
    return Material(
      child: Container(
        width: Get.width / 3,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          icon: icon,
        ),
      ),
    );
  }

  // العمليات
  Future<void> _handleTransition(
    String currentStatus,
    String nextStatus, {
    bool? isRejected,
  }) async {
    EngData engdata = EngData(
      orderNumber: widget.newOrderModel.orderNumber,
      username: widget.userName,
      usercode: widget.userCode,
      createdOn: DateTime.now(),
      orderStatus: currentStatus,
    );
    try {
      if (isRejected == true) {
        await _addRejectedCommentsDialog(engdata, nextStatus);
        await _deleteOrderFromSiteEngRate();
      } else if (isRejected == false) {
        await _addConfirmCommentDialog(engdata, nextStatus, currentStatus);
      } else {
        await _addReviewCommentDialog(engdata, nextStatus);
      }
    } catch (e) {
      _showErrorSnackbar(e);
    }
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

  Future<bool> _uploadFile(String folderId, String allowedExtensions) async {
    try {
      return await uploadFileFromDevice(
        context,
        fileName: widget.newOrderModel.orderNumber,
        orderNumber: widget.newOrderModel.orderNumber,
        userName: widget.userName,
        govName: widget.govName,
        folderId: folderId,
        allowedExtensions: allowedExtensions,
      );
    } catch (e) {
      _showErrorSnackbar(e);
      return false;
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
          .collection('PrOfficeTeamWork')
          .doc(widget.userName)
          .collection('PerRate');
      await FirebaseFirestore.instance
          .collection('PrOfficeTeamWork')
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

  Future<void> _deleteOrderFromSiteEngRate() async {
    await FirebaseFirestore.instance
        .collection('PrSiteTeamWork')
        .doc(widget.newOrderModel.engName)
        .collection('PerRate')
        .where('orderStatus', isEqualTo: "تم التسليم")
        .where('orderNumber', isEqualTo: widget.newOrderModel.orderNumber)
        .get()
        .then((querySnapshot) async {
          if (querySnapshot.docs.isNotEmpty) {
            await querySnapshot.docs.first.reference.delete();
          }
        });
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

  Future<void> _addRejectedCommentsDialog(
    EngData engdate,
    String nextStatus,
  ) async {
    await AwesomeDialog(
      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
      context: context,
      body: Column(
        children: [
          const Text(
            "اكتب سبب الرفض",
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
              .collection('rejected')
              // .doc(widget.newOrderModel.orderNumber)
              .add(commentsModel.toMap());
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
          await Future.delayed(const Duration(seconds: 2));
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
      },
    ).show();
  }

  Future<void> _addConfirmCommentDialog(
    EngData engdate,
    String nextStatus,
    String currentStatus,
  ) async {
    await AwesomeDialog(
      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
      context: context,
      body: Column(
        children: [
          const Text(
            "اكتب تعليق ",
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
      dismissOnTouchOutside: currentStatus != "Stage 1",
      dismissOnBackKeyPress: currentStatus != "Stage 1",
      btnCancelOnPress: currentStatus != "Stage 1" ? () {} : null,
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
              .collection('comments')
              // .doc(widget.newOrderModel.orderNumber)
              .add(commentsModel.toMap());
          EngData engdata = engdate;

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
          await Future.delayed(const Duration(seconds: 2));
          Get.back(closeOverlays: true);
        } else {
          Get.snackbar(
            "خطأ",
            "لايمكن التأكيد بدون تعليق",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    ).show();
  }

  Future<void> _addReviewCommentDialog(
    EngData engdate,
    String nextStatus,
  ) async {
    await AwesomeDialog(
      width: !kIsWeb && Platform.isAndroid ? null : Get.width / 2,
      context: context,
      body: Column(
        children: [
          const Text(
            "اكتب تعليق ",
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
              .collection('review_on_site')
              // .doc(widget.newOrderModel.orderNumber)
              .add(commentsModel.toMap());
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
          await Future.delayed(const Duration(seconds: 2));
          Get.back(closeOverlays: true);
        } else {
          Get.snackbar(
            "خطأ",
            "لايمكن التأكيد بدون تعليق",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    ).show();
  }

  Future<void> _showEngComments(bool isRejected) async {
    String collection;
    if (isRejected) {
      collection = "rejected";
    } else {
      collection = "comments";
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
            return const Center(child: CircularProgressIndicator());
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            " الاسم : $userName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            " الكود : $usercode",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            " التاريخ :${_formatDate(date)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: comments));
                            },
                            icon: const Icon(Icons.copy, size: 30),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "التعليق: $comments",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const Divider(),
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
