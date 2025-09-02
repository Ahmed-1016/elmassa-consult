// ignore_for_file: avoid_print

import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert'; // For utf8.decode
import 'dart:async'; // For TimeoutException
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // To get downloads directory
// import 'package:open_file/open_file.dart'; // Optional: to open the file after download

class DownloadPreviousFiles extends StatefulWidget {
  const DownloadPreviousFiles({super.key});

  @override
  State<DownloadPreviousFiles> createState() => _DownloadPreviousFilesState();
}

class _DownloadPreviousFilesState extends State<DownloadPreviousFiles> {
  String _message = 'أدخل رقم الطلب و اضغط على زر التحميل.';
  bool _isLoading = false;
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idController.clear();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<String?> _getDownloadsPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory(); // iOS: Documents directory
      } else if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory(); // For Android
      } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        directory = await getDownloadsDirectory();
      }
    } catch (err) {
      print("Cannot get downloads directory: $err");
      // Update message for the user if path is crucial and not found
      // setState(() {
      //  _message = "Could not access downloads directory. Please check permissions.";
      // });
    }
    return directory?.path;
  }

  Future<void> _downloadFile(String fieldName) async {
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _message = 'الرجاء إدخال رقم الطلب';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'جارى التحميل ...';
    });

    final String enteredId = _idController.text.trim();
   final headers = {
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language': 'en-US,en;q=0.9,ar;q=0.8',
    'priority': 'u=0, i',
    'referer': 'https://rscapps.edge-pro.com/Workflows/Form?workflow=mobile&lang=en-US&sessionid=${AppConstant.sissionid}&tenant=rsc_v2&nodeid=form',
    'sec-ch-ua': '"Not;A=Brand";v="99", "Microsoft Edge";v="139", "Chromium";v="139"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'iframe',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0',
  };

    final params = {
      'workflow': 'mobile',
      'lang': 'en-US',
      'sessionid': AppConstant.sissionid,
      'tenant': 'rsc_v2',
      'nodeid': 'form',
      'id': enteredId,
      'fieldName': fieldName,
    };

    final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/Form/DownloadFile')
        .replace(queryParameters: params);

    String successMessage = '';
    String errorMessage = '';
    IOClient? ioClient; // Declare ioClient here to access in finally block

    try {
      // Create a custom HttpClient that bypasses SSL certificate verification
      final httpClient = HttpClient();
      httpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      ioClient = IOClient(httpClient); // Initialize ioClient

      print('[DEBUG] _downloadFile: Making HTTP GET request to $url with custom client');
      final res = await ioClient.get(url, headers: headers).timeout(const Duration(seconds: 60));
      final status = res.statusCode;

      if (status != 200) {
        print('Could not decode response body.');
        try {
          utf8.decode(res.bodyBytes);
        } catch (e) {
          print('[ERROR] _downloadFile: Failed to decode response body: $e');
          // Keep default error message
        }
        errorMessage = 'من فضلك تأكد من رقم الطلب';
      } else {
        final String? downloadsPath = await _getDownloadsPath();
        if (downloadsPath == null) {
          print('[ERROR] _downloadFile: downloadsPath is null. Could not determine downloads directory.');
          errorMessage = 'Could not determine downloads directory. Please ensure permissions are granted.';
        } else {
          String fileExtension = '.dat'; // Default extension
          String originalFileName = params['fieldName']!;

          final disposition = res.headers['content-disposition'];
          if (disposition != null) {
            // Corrected RegExp for filename extraction
            final match = RegExp(r'filename\*?=(?:UTF-8'')?([^;]+)|filename=(?:\"([^;\"]+)\"|([^;]+))', caseSensitive: false).firstMatch(disposition);
            String? headerFileName;
            if (match?.group(1) != null) { // Check for filename* (RFC 5987)
                try { headerFileName = Uri.decodeComponent(match!.group(1)!); } catch (e) { print('[ERROR] _downloadFile: Failed to decode filename from Content-Disposition (filename*): $e'); }
            } else if (match?.group(2) != null) { // Check for filename=\"...\""
                headerFileName = match!.group(2);
            } else if (match?.group(3) != null) { // Check for filename=...
                headerFileName = match!.group(3);
            }

            // Remove leading/trailing quotes from headerFileName if present
            if (headerFileName != null && headerFileName.startsWith('"') && headerFileName.endsWith('"')) {
              headerFileName = headerFileName.substring(1, headerFileName.length - 1);
            }

            if (headerFileName != null && headerFileName.isNotEmpty) {
              originalFileName = headerFileName;
              if (headerFileName.contains('.')) {
                fileExtension = '.${headerFileName.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
              }
            }
          }

          // Sanitize enteredId for use in filename
          final sanitizedId = enteredId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
          // Sanitize originalFileName to remove path characters and keep base name + extension part
          final baseFileName = originalFileName.split(RegExp(r'[/\\]')).last.split('.').first;

          final fileName = "${baseFileName}_$sanitizedId$fileExtension";
          final File file = File('$downloadsPath/$fileName');

          await file.writeAsBytes(res.bodyBytes);
          successMessage = 'File downloaded successfully to: ${file.path}';

          // Optional: Open the file
          // try {
          //   final result = await OpenFile.open(file.path);
          //   if (result.type != ResultType.done) {
          //      successMessage += '\nCould not auto-open file: ${result.message}';
          //   }
          // } catch (e) {
          //   print('Could not open file: $e');
          //   successMessage += '\nError trying to auto-open file.';
          // }
        }
      }
    } on TimeoutException catch (_) {
      errorMessage = 'Error: The request timed out after 60 seconds.';
    } on http.ClientException catch (e) {
      errorMessage = 'Network Error (HTTP): ${e.message}';
    } on SocketException catch (e) {
      errorMessage = 'Network Error (Socket): ${e.message}. Check internet connection.';
    } catch (e) {
      errorMessage = 'An unexpected error occurred: ${e.toString()}';
      print('[ERROR] _downloadFile: Unexpected error: $e'); // Added print for the general catch
    } finally {
      ioClient?.close(); // Close the client in the finally block
      setState(() {
        _isLoading = false;
        if (errorMessage.isNotEmpty) {
          _message = errorMessage;
        } else if (successMessage.isNotEmpty) {
          _message = successMessage;
        } else {
          _message = 'Download process finished.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحميل ملفات الطلبات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الطلب',
                      hintText: 'XX-XXXX-X(X)-XXXXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'لصق رقم الطلب',
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null && clipboardData.text != null) {
                      _idController.text = clipboardData.text!;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 8.0, // Horizontal gap between buttons
              runSpacing: 8.0, // Vertical gap between lines of buttons
              alignment: WrapAlignment.center,
              children: <Widget>[
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_name'),
                    child: const Text('ملف المبنى CAD')), // attach_name
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_selim_manwar_name'),
                    child: const Text('ملف الوحدة CAD')), // attach_selim_manwar_name
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_land_name'),
                    child: const Text('ملف الارض CAD')), // attach_land_name
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_cad_img'),
                    child: const Text('صورة الكاد')), // attach_cad_img
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_3aqd'),
                    child: const Text('صورة العقد')), // attach_3aqd
                ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadFile('attach_layout'),
                    child: const Text('ملفات إخراج الشهادة')), // attach_layout
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("يرجى الانتظار"),
              )),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (_message.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy Message',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _message));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Message copied to clipboard')),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }}