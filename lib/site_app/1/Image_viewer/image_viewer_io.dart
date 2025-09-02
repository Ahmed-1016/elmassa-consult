// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

class ImageViewerPage extends StatefulWidget {
  final String requestNumber;

  const ImageViewerPage({Key? key, required this.requestNumber}) : super(key: key);

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late Future<drive.DriveApi> _driveApiFuture;
  drive.File? _imageFile; // Stores a single image file
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _driveApiFuture = _connectToDriveHelper();
    _loadImages();
  }

  Future<drive.DriveApi> _connectToDriveHelper() async {
    const credentialsPath = 'assets/serviceAccountKey.json'; // Ensure this path is correct
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

  Future<void> _loadImages() async {
    try {
      EasyLoading.show(status: "جارٍ تحميل الصور...");
      final driveApi = await _driveApiFuture;
      final parentFolderId = "1zy4sG4Fg8FlQQbroG1xkvyo0NjXZ1ahG";
      // Query for image files (jpeg or png) within the specified folder
      final query =
          "'$parentFolderId' in parents and (mimeType contains 'image/jpeg' or mimeType contains 'image/png') and trashed = false";
      // Request specific fields to reduce data transfer, especially thumbnailLink for previews
      // Request specific fields, ensure id, name, and webViewLink are fetched.
      // thumbnailLink is good for previews, but webViewLink might be needed for full quality if direct image links are not available.
      // For direct image display, consider using a direct download link if available, or fetching image bytes.
      final response = await driveApi.files.list(q: query, $fields: "files(id, name, webViewLink, thumbnailLink, webContentLink)");

      if (response.files != null && response.files!.isNotEmpty) {
        drive.File? foundFile;
        for (var file in response.files!) {
          if (file.name != null) {
            String fileNameWithoutExtension = file.name!;
            int dotIndex = fileNameWithoutExtension.lastIndexOf('.');
            if (dotIndex != -1) {
              fileNameWithoutExtension = fileNameWithoutExtension.substring(0, dotIndex);
            }
            if (fileNameWithoutExtension == widget.requestNumber) {
              foundFile = file;
              break; // Found the matching file
            }
          }
        }

        if (foundFile != null) {
          setState(() {
            _imageFile = foundFile;
          });
        } else {
          // No file matching the requestNumber was found
          Get.snackbar(
            "معلومة",
            "لاتوجد شهادة",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          // Ensure _imageFile is null if no match is found
          setState(() {
            _imageFile = null;
          });
        }
      } else {
        Get.snackbar(
          "معلومة",
          "لا توجد شهادة",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error loading images: $e");
      Get.snackbar(
        "خطأ",
        "حدث خطأ أثناء تحميل الصور: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      EasyLoading.dismiss();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareImage() async {
    if (_imageFile != null && _imageFile!.webViewLink != null) {
      try {
        await Share.share('Check out this image: ${_imageFile!.webViewLink}');
      } catch (e) {
        print('Error sharing image: $e');
        Get.snackbar(
          "خطأ",
          "حدث خطأ أثناء محاولة مشاركة الصورة.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        "معلومة",
        "لا توجد صورة لمشاركتها أو رابط المشاركة غير متوفر.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("عرض الصورة"), // Updated title
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _imageFile != null && _imageFile!.webViewLink != null 
                       ? _shareImage 
                       : null, // Disable button if no image or link
            tooltip: 'مشاركة الصورة',
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<drive.DriveApi>(
          future: _driveApiFuture,
          builder: (context, snapshot) {
            if (_isLoading) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("خطأ في الاتصال بالدرايف: ${snapshot.error}");
            } else if (_imageFile == null) {
              // This message will now also show if no image matched the requestNumber
              return Text("لا توجد شهادة");
            } else {
              // Use webContentLink for better quality if available, otherwise thumbnailLink.
              // For true full-resolution, you might need to handle Drive API's download mechanism.
              final imageUrl = _imageFile!.webContentLink ?? _imageFile!.thumbnailLink;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InteractiveViewer(
                      panEnabled: true, // Enable panning
                      minScale: 0.5, // Minimum scale allowed
                      maxScale: 4.0, // Maximum scale allowed
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain, // Use contain to see the whole image while zooming
                              errorBuilder: (context, error, stackTrace) {
                                print("Error loading image ${_imageFile!.name}: $error");
                                return Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey[700]));
                              },
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700])),
                    ),
                  ),
                  if (_imageFile!.name != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _imageFile!.name!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

// Example of how to navigate to this page:
// Get.to(() => ImageViewerPage(requestNumber: "your_request_number_here"));
// Make sure you have 'assets/serviceAccountKey.json' in your pubspec.yaml and the file exists.
