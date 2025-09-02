// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ElMassaConsult/utils/http_client.dart';
import 'package:ElMassaConsult/utils/app-constant.dart';


class GetRejectedComments extends StatefulWidget {
  const GetRejectedComments({Key? key}) : super(key: key);

  @override
  State<GetRejectedComments> createState() => _GetRejectedCommentsState();
}

List<String> loadedRequests = [];
bool _isExporting = false;
String? _currentRequestId;
int _remainingCount = 0;
String? _loadedSheetName;
String? _selectedFileName; // متغير لتخزين اسم الملف

class _GetRejectedCommentsState extends State<GetRejectedComments> {
  String _message = 'اضغط الزر لاختيار ملف';
  bool _isLoading = false;
    final CustomHttpClient _client = CustomHttpClient();

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<List<String>> readRequestNumbersFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      List<String> requestNumbers = [];

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows.skip(1)) {
          final cell = row[0];
          if (cell != null) {
            requestNumbers.add(cell.value.toString());
          }
        }
        break; // أول شيت فقط
      }

      _selectedFileName = result.files.single.name; // 👈 اسم الملف
      return requestNumbers;
    } else {
      _selectedFileName = null;
      return [];
    }
  }

  Future<Map<String, String?>> getCommentForRequest(String requestId) async {
    try {
          final Map<String, String> headers = {
        'accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'accept-language': 'en-US,en;q=0.9,ar;q=0.8',
        'referer': 'https://rscapps.edge-pro.com/Workflows/List?workflow=mobile',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/136.0.0.0 Safari/537.36',
      };

      final params = {
        'workflow': 'mobile',
        'lang': 'en-US',
        'sessionid': AppConstant.sissionid,
        'tenant': 'rsc_v2',
        'nodeid': 'form',
        'id': requestId,
        'tableField': 'survey_review_comments',
      };

      List<dynamic> allRows = [];
      int currentPage = 1;
      int pageSize = 15;
      int totalRows = 0;

      while (true) {
        final data = jsonEncode({
          "requestnumber": requestId,
          "take": pageSize,
          "skip": (currentPage - 1) * pageSize,
          "page": currentPage,
          "pageSize": pageSize,
          "sort": []
        });
        final url = Uri.parse('https://rscapps.edge-pro.com/Workflows/Form/PageTableData')
            .replace(queryParameters: params);

        final clientFech = HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;

        try {
          final request = await clientFech.postUrl(url);
          request.headers.set('content-type', 'application/json');
          request.headers.set('accept', 'application/json');
          request.write(data);

          final response = await request.close();
          if (response.statusCode != 200) {
            print('HTTP Error: ${response.statusCode}');
            throw Exception('HTTP Error: ${response.statusCode}');
          }
          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody);
          final rows = json['data']['rows'] ?? [];
          totalRows = json['data']['totalrowcount'] ?? 0;
          allRows.addAll(rows);
          
          final totalPages = (totalRows / pageSize).ceil();
          if (currentPage >= totalPages) break;

          currentPage++;
        } finally {
          clientFech.close();
        }
      }

      if (allRows.isNotEmpty) {
        final dateFormat = DateFormat('M/d/yyyy h:mm:ss a');
        try {
          allRows.sort((a, b) {
            final aDate = dateFormat.parse(a['fields']['comment_time'], true);
            final bDate = dateFormat.parse(b['fields']['comment_time'], true);
            return bDate.compareTo(aDate);
          });
        } catch (e) {
          print('Error sorting comments: $e');
        }

        final latest = allRows.first['fields'];
        return {
          'request_id': requestId,
          'comment': latest['comment'] ?? '',
          'comment_time': latest['comment_time'] ?? '',
        };
      }

      return {
        'request_id': requestId,
        'comment': 'لا يوجد تعليق',
        'comment_time': '',
      };
    } catch (e) {
      print('Error fetching comment for request $requestId: $e');
      return {
        'request_id': requestId,
        'comment': 'خطأ: ${e.toString()}',
        'comment_time': DateTime.now().toString(),
      };
    }
  }

  Future<void> exportToExcel(List<Map<String, String?>> data) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد تعليقات لتصديرها')),
          );
        }
        return;
      }

      final excel = Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet()!;
      excel.rename(defaultSheet, 'Comments');
      final sheet = excel['Comments'];

      List<String> headers = ['رقم الطلب', 'التعليق', 'تاريخ التعليق'];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      data.sort((a, b) {
        final aTime = a['comment_time'] ?? '';
        final bTime = b['comment_time'] ?? '';
        return bTime.compareTo(aTime);
      });

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
            .value = TextCellValue(row['request_id'] ?? '');

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
            .value = TextCellValue(row['comment'] ?? '');

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = TextCellValue(row['comment_time'] ?? '');
      }

      final dir = await getApplicationDocumentsDirectory();
      String baseFileName = 'تعليقات_الطلبات';
      String extension = '.xlsx';
      int counter = 0;
      File file;

      do {
        counter++;
        String fileName = counter == 1
            ? '$baseFileName$extension'
            : '${baseFileName}_$counter$extension';
        file = File('${dir.path}/$fileName');
      } while (await file.exists());

      await file.writeAsBytes(excel.encode()!);

      final result = await OpenFile.open(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.type == ResultType.done
                  ? 'تم تصدير البيانات وفتح الملف'
                  : 'تم التصدير ولكن لم يتم فتح الملف: ${result.message}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> processExcelRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _message = 'جاري قراءة الملف...';
    });

    try {
      final requestIds = await readRequestNumbersFromExcel();
      if (requestIds.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _message = 'الملف فارغ أو لم يتم اختياره';
          });
        }
        return;
      }

      List<Map<String, String?>> results = [];
      for (final id in requestIds) {
        if (!mounted) break;

        final commentData = await getCommentForRequest(id);
        results.add(commentData);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (mounted) {
        await exportToExcel(results);
      }
    } catch (e) {
      print('Error processing Excel requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'حدث خطأ: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: const Text('تعليقات الادارة')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_message),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final requestIds = await readRequestNumbersFromExcel();
                      _selectedFileName = _selectedFileName ?? '';

                      if (requestIds.isNotEmpty) {
                        setState(() {
                          loadedRequests = requestIds;
                          _loadedSheetName = _selectedFileName;
                          _message =
                              'تم تحميل الملف من الشيت "$_loadedSheetName"، اضغط لاستخراج البيانات';
                        });
                      } else {
                        setState(() {
                          _message = 'لم يتم اختيار ملف صالح';
                        });
                      }
                    },
                    icon: const Icon(Icons.file_open),
                    label: const Text('تحميل ملف Excel'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (loadedRequests.isEmpty || _isExporting)
                        ? null
                        : () async {
                            setState(() {
                              _isExporting = true;
                              _remainingCount = loadedRequests.length;
                            });

                            List<Map<String, String?>> results = [];

                            for (final id in loadedRequests) {
                              setState(() {
                                _currentRequestId = id;
                                _remainingCount =
                                    loadedRequests.length - results.length;
                              });

                              final comment = await getCommentForRequest(id);
                              results.add(comment);

                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                            }

                            await exportToExcel(results);

                            setState(() {
                              _isExporting = false;
                              _currentRequestId = null;
                              _remainingCount = 0;
                            });
                          },
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: _isExporting
                        ? Text(
                            'جاري جلب $_currentRequestId (المتبقي: $_remainingCount)')
                        : const Text('استخراج التعليقات'),
                  ),
                ],
              ),
      ),
    );
  }
}
