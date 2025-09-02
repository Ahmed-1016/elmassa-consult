import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ElMassaConsult/models/engdata-model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class DriveService {
  //السيرفر

  Future<drive.DriveApi> _connectToDrive() async {
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

  Future<bool> uploadFileFromDevice(BuildContext context,
      {required String fileName,
      required String userName,
      required String govName,
      required String orderNumber,
      required String userCode,
      required EngData engData}) async {
    try {
      EasyLoading.show(status: "انتظر من فضلك");

      String newFileName = '$fileName.rar';
      final driveApi = await _connectToDrive();

      String baseName = '$fileName.rar';
      String escapedFileName = fileName.replaceAll("'", "''");

      const parentFolderId = '1-5QqDEa_xPetpe3IKq1AbmhFsSezcxKj';
      final query =
          "'$parentFolderId' in parents and name starts with '$escapedFileName' and trashed = false";
      final response = await driveApi.files.list(q: query);

      List<drive.File> existingFiles = response.files ?? [];

      RegExp regex = RegExp('^${RegExp.escape(fileName)} \\((\\d+)\\)\\.rar\$');
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
        newFileName = '$fileName (${maxNumber + 1}).rar';
      } else {
        newFileName = baseName;
      }

      // دعم الويب
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['rar'],
          withData: true,
        );
        if (result == null || result.files.single.bytes == null) {
          EasyLoading.dismiss();
          return false;
        }
        final bytes = result.files.single.bytes!;
        final driveFile = drive.File()
          ..name = newFileName
          ..parents = [parentFolderId];
        final media = drive.Media(Stream.value(bytes), bytes.length);

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
      }

      // دعم الموبايل/ويندوز
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rar'],
      );

      if (fileResult == null || fileResult.files.single.path == null) {
        EasyLoading.dismiss();
        return false  ;
      }

      final file = File(fileResult.files.single.path!);

      final driveFile = drive.File()
        ..name = newFileName
        ..parents = [parentFolderId];

      final media = drive.Media(file.openRead(), file.lengthSync());

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
    }
    EasyLoading.dismiss();
    return false;
  }
}
