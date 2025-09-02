import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';

Future<drive.DriveApi> _connectToDriveHelper() async {
  const credentialsPath = 'assets/serviceAccountKey.json';
  final credentialsContent = await rootBundle.loadString(credentialsPath);
  final accountCredentials = ServiceAccountCredentials.fromJson(
    jsonDecode(credentialsContent),
  );

  final authClient = await clientViaServiceAccount(
    accountCredentials,
    [drive.DriveApi.driveScope],
  );

  return drive.DriveApi(authClient);
}

Future<void> downloadFileAction(
  BuildContext context,
  String orderNumber,
  String name,
) async {
  try {
    EasyLoading.show(status: "جارٍ تحميل الملف...");
    final driveApi = await _connectToDriveHelper();

    final parentFolderId = '1h8oObHLZcpDN_JsZReq0cBhdSrIl9Smc';

    final query =
        "'$parentFolderId' in parents and name contains '$orderNumber' and trashed = false";

    final response = await driveApi.files.list(q: query);

    if (response.files == null || response.files!.isEmpty) {
      EasyLoading.dismiss();
      Get.snackbar(
        "خطأ",
        "لم يتم العثور على الملف المطلوب",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final matchingFiles = response.files!
        .where((file) => file.name!.startsWith(orderNumber))
        .toList();

    if (matchingFiles.isEmpty) {
      EasyLoading.dismiss();
      Get.snackbar(
        "خطأ",
        "لم يتم العثور على ملف مطابق للاسم: $orderNumber",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    matchingFiles.sort((a, b) {
      final regex = RegExp(r'\((\d+)\)\.rar$');
      final aMatch = regex.firstMatch(a.name!);
      final bMatch = regex.firstMatch(b.name!);

      final aNumber = aMatch != null ? int.parse(aMatch.group(1)!) : 0;
      final bNumber = bMatch != null ? int.parse(bMatch.group(1)!) : 0;

      return bNumber.compareTo(aNumber); // Sort descending
    });

    final latestFile = matchingFiles.first;
    final fileId = latestFile.id!;

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    String fileName = latestFile.name ?? "$name.rar";

    // دعم الموبايل/الديسكتوب
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      EasyLoading.dismiss();
      Get.snackbar(
        "خطأ",
        "تعذر الوصول إلى دليل التنزيلات",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    String filePath = '${directory.path}/$fileName';
    int counter = 1;
    while (File(filePath).existsSync()) {
      filePath = '${directory.path}/$name(${counter++}).rar';
    }

    final file = File(filePath);
    final fileSink = file.openWrite();
    await media.stream.pipe(fileSink);
    await fileSink.close();

    EasyLoading.dismiss();
    Get.snackbar(
      "نجاح",
      "تم تحميل الملف بنجاح: $filePath",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    EasyLoading.dismiss();
    print("Error downloading file: $e");
    Get.snackbar(
      "خطأ",
      "حدث خطأ أثناء تحميل الملف: ${e.toString()}",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
