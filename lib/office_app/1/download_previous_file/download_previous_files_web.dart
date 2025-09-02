// ignore_for_file: avoid_print

import 'package:ElMassaConsult/utils/app-constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DownloadPreviousFiles extends StatefulWidget {
  const DownloadPreviousFiles({super.key});

  @override
  State<DownloadPreviousFiles> createState() => _DownloadPreviousFilesState();
}

class _DownloadPreviousFilesState extends State<DownloadPreviousFiles> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;
  String _message = 'أدخل رقم الطلب واضغط على زر التحميل.';

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
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

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes]);

String fileExtension = '.dat'; // Default extension
String originalFileName = params['fieldName']!;
final disposition = response.headers['content-disposition'];

if (disposition != null) {
  final match = RegExp(
          r'filename\*?=(?:UTF-8'')?([^;]+)|filename=\"?([^;\"]+)\"?',
          caseSensitive: false)
      .firstMatch(disposition);
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

// Safe filename building
final sanitizedId = enteredId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
final baseFileName = originalFileName.split(RegExp(r'[/\\]')).last.split('.').first;
final fileName = "${baseFileName}_$sanitizedId$fileExtension";

// Download
final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
html.AnchorElement(href: downloadUrl)
  ..target = 'blank'
  ..download = fileName
  ..click();
html.Url.revokeObjectUrl(downloadUrl);

setState(() {
  _message = 'تم تحميل الملف: $fileName';
});
      } else {
        setState(() {
          _message = 'من فضلك تأكد من رقم الطلب';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'حدث خطأ أثناء التحميل: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحميل ملفات الطلبات (ويب)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'رقم الطلب',
                      hintText: 'XX-XXXX-X(X)-XXXXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final clipboardData =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null && clipboardData.text != null) {
                      _idController.text = clipboardData.text!;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _downloadFile('attach_name'),
                    child: const Text('ملف المبنى CAD')),
                ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _downloadFile('attach_selim_manwar_name'),
                    child: const Text('ملف الوحدة CAD')),
                ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _downloadFile('attach_land_name'),
                    child: const Text('ملف الأرض CAD')),
                ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _downloadFile('attach_cad_img'),
                    child: const Text('صورة الكاد')),
                ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _downloadFile('attach_3aqd'),
                    child: const Text('صورة العقد')),
                ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _downloadFile('attach_layout'),
                    child: const Text('ملفات إخراج الشهادة')),
              ],
            ),
            const SizedBox(height: 30),
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            SelectableText(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
