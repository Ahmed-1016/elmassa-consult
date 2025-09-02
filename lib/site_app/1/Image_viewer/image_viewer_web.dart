// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageViewerPage extends StatefulWidget {
  final String requestNumber;

  const ImageViewerPage({Key? key, required this.requestNumber}) : super(key: key);

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImageFromDrive();
  }

  Future<drive.DriveApi> _connectToDriveHelper() async {
    const credentialsPath = 'assets/serviceAccountKey.json';
    final credentialsContent = await rootBundle.loadString(credentialsPath);
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(credentialsContent));
    final authClient = await clientViaServiceAccount(accountCredentials, [drive.DriveApi.driveScope]);
    return drive.DriveApi(authClient);
  }

  Future<void> _loadImageFromDrive() async {
    try {
      EasyLoading.show(status: "جارٍ تحميل الصورة...");
      final driveApi = await _connectToDriveHelper();
      const parentFolderId = '1zy4sG4Fg8FlQQbroG1xkvyo0NjXZ1ahG';
      final query = "'$parentFolderId' in parents and name contains '${widget.requestNumber}' and trashed = false";
      final response = await driveApi.files.list(q: query);

      if (response.files == null || response.files!.isEmpty) {
        throw Exception("لم يتم العثور على صورة");
      }

      final file = response.files!.firstWhereOrNull(
        (f) => f.name!.startsWith(widget.requestNumber),
      );

      if (file == null) throw Exception("لا توجد صورة تطابق الرقم المطلوب");

      final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytesBuilder = await media.stream.fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d));
      setState(() {
        _imageBytes = bytesBuilder.takeBytes();
      });

      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar("خطأ", "${e.toString()}", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _imageBytes = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _downloadImage() {
    if (_imageBytes == null) return;
    final blob = html.Blob([_imageBytes!]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '${widget.requestNumber}.jpg')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("عرض الصورة"),
        actions: [
          if (_imageBytes != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadImage,
            ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _imageBytes != null
                ? InteractiveViewer(
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  )
                : const Text("لا توجد صورة")
      ),
    );
  }
}

// Example Usage:
// Get.to(() => ImageViewerWebPage(requestNumber: "your_request_number_here"));
