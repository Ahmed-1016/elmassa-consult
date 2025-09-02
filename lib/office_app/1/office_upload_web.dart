import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

Future<drive.DriveApi> _connectToDrive() async {
  const credentialsPath = 'assets/serviceAccountKey.json';
  final credentialsContent = await rootBundle.loadString(credentialsPath);
  final accountCredentials = ServiceAccountCredentials.fromJson(
    jsonDecode(credentialsContent),
  );

  final authClient = await clientViaServiceAccount(accountCredentials, [
    drive.DriveApi.driveScope,
  ]);

  return drive.DriveApi(authClient);
}

Future<bool> uploadFileFromDevice(
  BuildContext context, {
  required String fileName,
  required String userName,
  required String govName,
  required String orderNumber,
  required String folderId,
  required String allowedExtensions,
}) async {
  try {
    EasyLoading.show(status: "انتظر من فضلك");

    String newFileName = '$fileName.$allowedExtensions';
    final driveApi = await _connectToDrive();

    String baseName = '$fileName.$allowedExtensions';
    String escapedFileName = fileName.replaceAll("'", "''");

    String parentFolderId = folderId;
    final query =
        "'$parentFolderId' in parents and name starts with '$escapedFileName' and trashed = false";
    final response = await driveApi.files.list(q: query);

    List<drive.File> existingFiles = response.files ?? [];
    RegExp regex = RegExp(
      '^${RegExp.escape(fileName)} \\((\\d+)\\)\\.$allowedExtensions\$',
    );
    List<int> numbers = [];

    for (drive.File file in existingFiles) {
      if (file.name == baseName) {
        numbers.add(0);
      } else {
        RegExpMatch? match = regex.firstMatch(file.name ?? '');
        if (match != null) {
          int? number = int.tryParse(match.group(1)!);
          if (number != null) {
            numbers.add(number);
          }
        }
      }
    }

    if (numbers.isNotEmpty) {
      int maxNumber = numbers.reduce((a, b) => a > b ? a : b);
      newFileName = '$fileName (${maxNumber + 1}).$allowedExtensions';
    } else {
      newFileName = baseName;
    }

    // Web implementation
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.$allowedExtensions';
    
    final completer = Completer<Uint8List?>();
    
    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      
      final file = files[0];
      final fileExtension = file.name.split('.').last.toLowerCase();
      
      // Validate file extension
      if (fileExtension != allowedExtensions.toLowerCase()) {
        Get.snackbar(
          'خطأ',
          'نوع الملف غير مسموح به. يرجى تحميل ملف بصيغة .$allowedExtensions فقط',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        completer.complete(null);
        return;
      }
      
      final reader = html.FileReader();
      
      reader.onError.listen((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
      
      reader.onLoadEnd.listen((e) {
        try {
          if (reader.result != null) {
            final bytes = (reader.result as List<int>).cast<int>();
            completer.complete(Uint8List.fromList(bytes));
          } else {
            completer.complete(null);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });
      
      try {
        reader.readAsArrayBuffer(file);
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });
    
    // Trigger file selection dialog
    uploadInput.click();
    
    // Set a timeout for file selection
    final fileBytes = await completer.future.timeout(
      const Duration(seconds: 120), // 2 minutes timeout
      onTimeout: () {
        Get.snackbar(
          'خطأ',
          'انتهت مهلة انتظار تحميل الملف',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      },
    );
    if (fileBytes == null) {
      EasyLoading.dismiss();
      return false;
    }

    final driveFile = drive.File()
      ..name = newFileName
      ..parents = [parentFolderId];

    final media = drive.Media(
      Stream.value(fileBytes),
      fileBytes.length,
      contentType: 'application/octet-stream',
    );

    await driveApi.files.create(driveFile, uploadMedia: media);

    Get.snackbar(
      'نجاح',
      'تم الرفع بنجاح: $newFileName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    EasyLoading.dismiss();
    return true;
  } catch (e) {
    Get.snackbar(
      "خطأ",
      'خطأ في الرفع: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    EasyLoading.dismiss();
    return false;
  }
}
